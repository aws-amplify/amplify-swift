//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
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
        withExtendedLifetime(cancellables) { }
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
            for index in 0 ..< concurrentFactor {
                let id = UUID().uuidString
                taskGroup.addTask { [weak self] () -> AnyCancellable? in
                    guard let self else { return nil }
                    let subscription = try await makeOneSubscription(id: id) {
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
        withExtendedLifetime(cancellables) { }
    }

    func testMaxSubscriptionReached_throwMaxSubscriptionsReachedError() async throws {
        let numOfMaxSubscriptionCount = 200
        let maxSubsctiptionsSuccess = expectation(description: "Client can subscribe to max subscription count")
        maxSubsctiptionsSuccess.expectedFulfillmentCount = numOfMaxSubscriptionCount

        var cancellables = try await withThrowingTaskGroup(
            of: AnyCancellable?.self,
            returning: [AnyCancellable?].self
        ) { taskGroup in
            for index in 0 ..< numOfMaxSubscriptionCount {
                let id = UUID().uuidString
                taskGroup.addTask { [weak self] () -> AnyCancellable? in
                    guard let self else { return nil }
                    let subscription = try await makeOneSubscription(id: id) {
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
        try await cancellables.append(makeOneSubscription { event in
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
        withExtendedLifetime(cancellables) { }
    }

    // End-to-end regression test for https://github.com/aws-amplify/amplify-swift/issues/3976
    //
    // Drives a real AppSync subscription through an AmplifyNetworkMonitor we
    // own, then simulates the scenePhase-triggered NWPath recycle by sending
    // a second .online state. In the buggy WebSocketClient, the scan produces
    // (.online, .online), onNetworkStateChange hits `default: break`, the
    // URLSessionWebSocketTask is left zombied, and no new subscription events
    // arrive. With the fix, the client tears down and reconnects, and the
    // subscription is re-established.
    //
    // Requires GraphQLModelBasedTests-amplifyconfiguration.json at
    // ~/.aws-amplify/amplify-ios/testconfiguration/ (same as all other tests
    // in this file). If missing, test fails in setUp rather than here.
    func testSubscribe_afterOnlineToOnlinePathChange_shouldRecycleAndResubscribe() async throws {
        var cancellables = Set<AnyCancellable>()

        let data = try TestConfigHelper.retrieve(
            forResource: GraphQLModelBasedTests.amplifyConfiguration
        )
        let amplifyConfig = try JSONDecoder().decode(JSONValue.self, from: data)
        let (endpoint, apiKey) = (amplifyConfig.api?.plugins?.awsAPIPlugin?.asObject?.values
            .map { ($0.endpoint?.stringValue, $0.apiKey?.stringValue) }
            .first { $0.0 != nil && $0.1 != nil }
            .map { ($0.0!, $0.1!) })!

        // Inject a real AmplifyNetworkMonitor we can drive directly.
        let networkMonitor = AmplifyNetworkMonitor()

        let webSocketClient = WebSocketClient(
            url: AppSyncRealTimeClientFactory.appSyncRealTimeEndpoint(URL(string: endpoint)!),
            handshakeHttpHeaders: [
                URLRequestConstants.Header.webSocketSubprotocols: "graphql-ws",
                URLRequestConstants.Header.userAgent: AmplifyAWSServiceConfiguration.userAgentLib + " (intg-test-3976)"
            ],
            interceptor: APIKeyAuthInterceptor(apiKey: apiKey),
            networkMonitor: networkMonitor
        )
        let client = AppSyncRealTimeClient(
            endpoint: URL(string: endpoint)!,
            requestInterceptor: APIKeyAuthInterceptor(apiKey: apiKey),
            webSocketClient: webSocketClient
        )
        defer { Task { await client.reset() } }

        // Wait for WebSocketClient's internal sink to attach to the monitor's
        // publisher (it's kicked off via a Task in init). Prime with .online
        // AFTER the subscriber is attached so the PassthroughSubject actually
        // delivers the event. This gets the scan to (.none, .online) —
        // WebSocketClient will ignore it because autoConnect is still false.
        try await Task.sleep(nanoseconds: 200_000_000)
        await networkMonitor.updateState(.online)

        let firstSubscribed = expectation(description: "Initial subscription established")
        let resubscribedAfterPathChange = expectation(description: "Subscription re-established after (.online, .online)")
        resubscribedAfterPathChange.assertForOverFulfill = false

        let id = UUID().uuidString
        var subscribedCount = 0
        let subscription = try await client.subscribe(
            id: id,
            query: Self.appSyncQuery(with: subscriptionRequest)
        ).sink { event in
            if case .subscribed = event {
                subscribedCount += 1
                if subscribedCount == 1 {
                    firstSubscribed.fulfill()
                } else {
                    resubscribedAfterPathChange.fulfill()
                }
            }
        }
        cancellables.insert(subscription)

        try await client.connect()
        await fulfillment(of: [firstSubscribed], timeout: 10)

        // Simulate the path-recycle: second .online emission produces
        // (.online, .online) through the scan — the exact bug tuple.
        // In the buggy code, nothing happens; WebSocketClient keeps the
        // zombie connection. With the fix, it should tear down and reconnect,
        // and AppSyncRealTimeClient.resumeExistingSubscriptions() should
        // re-subscribe.
        await networkMonitor.updateState(.online)

        await fulfillment(of: [resubscribedAfterPathChange], timeout: 15)
        withExtendedLifetime(cancellables) { }
    }

    private func makeOneSubscription(
        id: String = UUID().uuidString,
        onSubscriptionEvents: ((AppSyncSubscriptionEvent) -> Void)?
    ) async throws -> AnyCancellable? {
        let subscription = try await appSyncRealTimeClient?.subscribe(
            id: id,
            query: Self.appSyncQuery(with: subscriptionRequest)
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
            "variables": variables.isEmpty ? .null : .object(variables)
        ])
        let data = try JSONEncoder().encode(payload)
        return String(data: data, encoding: .utf8)!
    }

}
