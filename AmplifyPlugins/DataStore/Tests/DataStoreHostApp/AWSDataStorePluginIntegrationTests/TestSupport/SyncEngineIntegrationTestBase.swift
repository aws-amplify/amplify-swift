//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

class SyncEngineIntegrationTestBase: DataStoreTestBase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = SyncEngineIntegrationTestBase.networkTimeout

    // Convenience property to obtain a handle to the underlying storage adapter implementation, for use in asserting
    // database behaviors. Full of force-unwrapped badness.
    // swiftlint:disable force_try
    // swiftlint:disable force_cast
    var storageAdapter: SQLiteStorageEngineAdapter {
        let plugin = try! Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let storageEngine = plugin.storageEngine as! StorageEngine
        let storageAdapter = storageEngine.storageAdapter as! SQLiteStorageEngineAdapter
        return storageAdapter
    }
    // swiftlint:enable force_try
    // swiftlint:enable force_cast

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        try await super.tearDown()
        try await clearDataStore()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    func setUp(
        withModels models: AmplifyModelRegistration,
        logLevel: LogLevel = .error,
        dataStoreConfiguration: DataStoreConfiguration? = nil
    ) async {
        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(
                modelRegistration: models,
                sessionFactory: AmplifyURLSessionFactory()
            ))
            try Amplify.add(
                plugin: AWSDataStorePlugin(
                    modelRegistration: models,
                    configuration: dataStoreConfiguration ?? .custom(syncMaxRecords: 100)
                )
            )
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
    
    func stopDataStore() async throws {
        try await Amplify.DataStore.stop()
    }
    
    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }

    func getTestConfiguration() throws -> AmplifyConfiguration {
        try TestConfigHelper.retrieveAmplifyConfiguration(
            forResource: Self.amplifyConfigurationFile)
    }

    func startAmplify() throws {
        let amplifyConfig = try getTestConfiguration()
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func startAmplifyAndWaitForSync() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) async throws {
        try startAmplify()

        let eventReceived = expectation(description: "DataStore \(eventName) event")
        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: eventName) { _ in
            eventReceived.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try await HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try await Amplify.DataStore.start()

        await fulfillment(of: [eventReceived], timeout: 10)
    }

}
