//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
import Amplify
@testable import AWSAPIPlugin

class DataStoreLargeNumberModelsSubscriptionTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Blog6.self)
            registry.register(modelType: Comment.self)
            registry.register(modelType: Comment3.self)
            registry.register(modelType: Comment4.self)
            registry.register(modelType: Comment6.self)
            registry.register(modelType: CustomerOrder.self)
            registry.register(modelType: EnumTestModel.self)
            registry.register(modelType: ListIntContainer.self)
            registry.register(modelType: ListStringContainer.self)
            registry.register(modelType: Post.self)
            registry.register(modelType: Post3.self)
            registry.register(modelType: Post4.self)
            registry.register(modelType: Post5.self)
            registry.register(modelType: Post6.self)
            registry.register(modelType: Project1.self)
            registry.register(modelType: Project2.self)
            registry.register(modelType: Team1.self)
            registry.register(modelType: Team2.self)
            registry.register(modelType: User5.self)
        }

        let version: String = "1"
    }

    func testDataStoreStart_subscriptionsShouldBeEstablishedInReasonableTime() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        try await startDataStoreAndWaitForSubscriptionsEstablished(timeout: 2)
    }

    func testDataStoreStop_subscriptionsShouldAllUnsubscribed() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startAmplifyAndWaitForSync()

        try await stopDataStoreAndVerifyAppSyncClientDisconnected()
    }

    func testDataStoreStartStopRepeat_subscriptionShouldBehaviorCorrect() async throws {
        let repeatCount = 5
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        
        for _ in 0..<repeatCount {
            try await startDataStoreAndWaitForSubscriptionsEstablished(timeout: 2)
            try await stopDataStoreAndVerifyAppSyncClientDisconnected()
        }
    }

    private func startDataStoreAndWaitForSubscriptionsEstablished(timeout: TimeInterval) async throws {
        var cancellables = Set<AnyCancellable>()
        let expectation = expectation(description: "DataStore with 19 models should establish subscription in 2 seconds")
        Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.subscriptionsEstablished }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        Task {
            try await Amplify.DataStore.start()
        }
        await fulfillment(of: [expectation], timeout: timeout)
        withExtendedLifetime(cancellables, { })
    }

    private func stopDataStoreAndVerifyAppSyncClientDisconnected() async throws {
        try await Amplify.DataStore.stop()

        guard let awsApiPlugin = try? Amplify.API.getPlugin(for: "awsAPIPlugin") as? AWSAPIPlugin else {
            XCTFail("AWSAPIPlugin should not be nil")
            return
        }

        guard let appSyncRealTimeClientFactory =
                awsApiPlugin.appSyncRealTimeClientFactory as? AppSyncRealTimeClientFactory
        else {
            XCTFail("AppSyncRealTimeClientFactory should not be nil")
            return
        }

        let appSyncRealTimeClients = (await appSyncRealTimeClientFactory.apiToClientCache.values)
            .map { $0 as! AppSyncRealTimeClient }

        try await Task.sleep(seconds: 1)

        var allClientsDisconnected = true
        for client in appSyncRealTimeClients {
            let clientIsConnected = await client.isConnected
            allClientsDisconnected = allClientsDisconnected && !clientIsConnected
        }
        XCTAssertTrue(allClientsDisconnected)
    }
}
