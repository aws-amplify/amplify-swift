//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
@testable import Amplify
@testable import AWSAPIPlugin
@testable @_spi(AmplifySwift) import AWSPluginsCore

class AppSyncRealTimeClientTests: XCTestCase {
    let subscriptionRequest = """
    subscription MySubscription {
      onCreatePost {
        content
        createdAt
        draft
        id
        rating
        status
        title
        updatedAt
      }
    }
    """

    var appSyncRealTimeClient: AppSyncRealTimeClient?

    override func setUp() async throws {
        do {
            Amplify.Logging.logLevel = .verbose

            let data = try TestConfigHelper.retrieve(
                forResource: GraphQLModelBasedTests.amplifyConfiguration
            )
            
            let amplifyConfig = try JSONDecoder().decode(JSONValue.self, from: data)
            let (endpoint, apiKey) = (amplifyConfig.api?.plugins?.awsAPIPlugin?.asObject?.values
                .map { ($0.endpoint?.stringValue, $0.apiKey?.stringValue)}
                .first { $0.0 != nil && $0.1 != nil }
                .map { ($0.0!, $0.1!) })!


            let webSocketClient = WebSocketClient(
                url: AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(URL(string: endpoint)!),
                protocols: ["graphql-ws"],
                interceptor: APIKeyAuthInterceptor(apiKey: apiKey)
            )
            appSyncRealTimeClient = AppSyncRealTimeClient(
                endpoint: URL(string: endpoint)!,
                requestInterceptor: APIKeyAuthInterceptor(apiKey: apiKey),
                webSocketClient: webSocketClient
            )

        } catch {
            XCTFail("Failed to setup appSyncRealTimeClient: \(error)")
        }
    }

    override func tearDown() async throws {
        await appSyncRealTimeClient?.reset()
        appSyncRealTimeClient = nil
    }

    func testSubscribe_withSubscriptionConnection() async throws {
        var cancellables = Set<AnyCancellable>()
        let subscribedExpectation = expectation(description: "Subscription established")

        try await appSyncRealTimeClient?.connect()
        try await appSyncRealTimeClient?.subscribe(
            id: UUID().uuidString,
            query: Self.appSyncQuery(with: subscriptionRequest)
        )
        .sink(receiveCompletion: { completion in
            print("### completion \(completion)")
        }, receiveValue: { event in
            if case .subscribed = event {
                subscribedExpectation.fulfill()
            }
        })
        .store(in: &cancellables)
        await fulfillment(of: [subscribedExpectation], timeout: 5)
    }

    func testMultThreads_subscribeAndUnsubscribe() async throws {
        let concurrentFactor = 100
        let expectedSubscription = expectation(description: "Multi threads subscription")
        expectedSubscription.expectedFulfillmentCount = concurrentFactor

        let expectedUnsubscription = expectation(description: "Multi threads unsubscription")
        expectedUnsubscription.expectedFulfillmentCount = concurrentFactor
        _ = try await withThrowingTaskGroup(
            of: AnyCancellable?.self,
            returning: [AnyCancellable?].self
        ) { taskGroup in
            (0..<concurrentFactor).forEach { index in
                let id = UUID().uuidString
                taskGroup.addTask { [weak self] () -> AnyCancellable? in
                    guard let self else { return nil }
                    let subscription: AnyCancellable? = try await self.appSyncRealTimeClient?.subscribe(
                        id: id,
                        query: Self.appSyncQuery(with: self.subscriptionRequest)
                    )
                    .sink {
                        if case .subscribed = $0 {
                            expectedSubscription.fulfill()
                        } else if case .unsubscribed = $0 {
                            expectedUnsubscription.fulfill()
                        }
                    }
                    try await self.appSyncRealTimeClient?.unsubscribe(id: id)

                    return subscription
                }

            }

            return try await taskGroup.reduce([AnyCancellable?]()) { $0 + [$1] }
        }

        await fulfillment(of: [expectedSubscription, expectedUnsubscription], timeout:1)
    }

    private static func appSyncQuery(
        with query: String,
        variables: [String: JSONValue] = [:]
    ) throws -> String {
        let payload: JSONValue = .object([
            "query": .string(query),
            "variables": (variables.isEmpty ? .null : .object(variables))
        ])
        let data = try JSONEncoder().encode(payload)
        return String(data: data, encoding: .utf8)!
    }
}
