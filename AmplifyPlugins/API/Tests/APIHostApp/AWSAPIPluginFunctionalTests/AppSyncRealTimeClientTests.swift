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
@testable @_spi(WebSocket) import AWSPluginsCore
@testable import InternalAmplifyCredentials

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
                handshakeHttpHeaders: [
                    URLRequestConstants.Header.webSocketSubprotocols: "graphql-ws",
                    URLRequestConstants.Header.userAgent: AmplifyAWSServiceConfiguration.userAgentLib + " (intg-test)"
                ],
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
        try await makeOneSubscription { event in
            if case .subscribed = event {
                subscribedExpectation.fulfill()
            }
        }?.store(in: &cancellables)

        await fulfillment(of: [subscribedExpectation], timeout: 5)
        withExtendedLifetime(cancellables, { })
    }

    func testMultThreads_withConnectedClient_subscribeAndUnsubscribe() async throws {
        var cancellables = [AnyCancellable?]()
        let concurrentFactor = 90
        let expectedSubscription = expectation(description: "Multi threads subscription")
        expectedSubscription.expectedFulfillmentCount = concurrentFactor

        let expectedUnsubscription = expectation(description: "Multi threads unsubscription")
        expectedUnsubscription.expectedFulfillmentCount = concurrentFactor
        cancellables = try await withThrowingTaskGroup(
            of: AnyCancellable?.self,
            returning: [AnyCancellable?].self
        ) { taskGroup in
            (0..<concurrentFactor).forEach { index in
                let id = UUID().uuidString
                taskGroup.addTask { [weak self] () -> AnyCancellable? in
                    guard let self else { return nil }
                    let subscription = try await self.makeOneSubscription(id: id) {
                        if case .subscribed = $0 {
                            expectedSubscription.fulfill()
                            Task {
                                try await self.appSyncRealTimeClient?.unsubscribe(id: id)
                            }
                        } else if case .unsubscribed = $0 {
                            expectedUnsubscription.fulfill()
                        }
                    }

                    return subscription
                }

            }

            return try await taskGroup.reduce([AnyCancellable?]()) { $0 + [$1] }
        }

        await fulfillment(of: [expectedSubscription, expectedUnsubscription], timeout: 3)
        withExtendedLifetime(cancellables, { })
    }

    func testMaxSubscriptionReached_throwMaxSubscriptionsReachedError() async throws {
        let numOfMaxSubscriptionCount = 100
        let maxSubsctiptionsSuccess = expectation(description: "Client can subscribe to max subscription count")
        maxSubsctiptionsSuccess.expectedFulfillmentCount = numOfMaxSubscriptionCount

        var cancellables = try await withThrowingTaskGroup(
            of: AnyCancellable?.self,
            returning: [AnyCancellable?].self
        ) { taskGroup in
            (0..<numOfMaxSubscriptionCount).forEach { index in
                let id = UUID().uuidString
                taskGroup.addTask { [weak self] () -> AnyCancellable? in
                    guard let self else { return nil }
                    let subscription = try await self.makeOneSubscription(id: id) {
                        if case .subscribed = $0 {
                            maxSubsctiptionsSuccess.fulfill()
                        }
                    }

                    return subscription
                }
            }
            return try await taskGroup.reduce([AnyCancellable?]()) { $0 + [$1] }
        }

        await fulfillment(of: [maxSubsctiptionsSuccess], timeout: 2)

        let maxSubscriptionReachedError = expectation(description: "Should return max subscription reached error")
        maxSubscriptionReachedError.assertForOverFulfill = false
        let retryTriggerredAndSucceed = expectation(description: "Retry on max subscription reached error and succeed")
        cancellables.append(try await makeOneSubscription { event in
            if case .error(let errors) = event {
                XCTAssertTrue(errors.count == 1)
                XCTAssertTrue(errors[0] is AppSyncRealTimeRequest.Error)
                if case .maxSubscriptionsReached = errors[0] as! AppSyncRealTimeRequest.Error {
                    maxSubscriptionReachedError.fulfill()
                    cancellables.dropLast(10).forEach { $0?.cancel() }
                }
            } else if case .subscribed = event {
                retryTriggerredAndSucceed.fulfill()
            }
        })
        await fulfillment(of: [maxSubscriptionReachedError, retryTriggerredAndSucceed], timeout: 5, enforceOrder: true)
        withExtendedLifetime(cancellables, { })
    }

    private func makeOneSubscription(
        id: String = UUID().uuidString,
        onSubscriptionEvents: ((AppSyncSubscriptionEvent) -> Void)?
    ) async throws -> AnyCancellable? {
        let subscription = try await appSyncRealTimeClient?.subscribe(
            id: id,
            query: Self.appSyncQuery(with: self.subscriptionRequest)
        ).sink(receiveValue: {
            onSubscriptionEvents?($0)
        })

        return AnyCancellable {
            subscription?.cancel()
            Task { [weak self] in
                try? await self?.appSyncRealTimeClient?.unsubscribe(id: id)
            }
        }
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
