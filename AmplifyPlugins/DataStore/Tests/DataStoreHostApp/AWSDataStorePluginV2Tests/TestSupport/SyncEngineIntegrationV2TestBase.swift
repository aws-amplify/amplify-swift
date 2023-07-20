//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif
import AWSAPIPlugin

class SyncEngineIntegrationV2TestBase: DataStoreTestBase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(60)
    let networkTimeout = SyncEngineIntegrationV2TestBase.networkTimeout

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

    override func setUp() {
        continueAfterFailure = true
    }

    override func tearDown() async throws {
        try await Amplify.DataStore.clear()
        await Amplify.reset()
        try await Task.sleep(seconds: 1)
    }

    // swiftlint:enable force_try
    // swiftlint:enable force_cast

    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) async {

        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(
                modelRegistration: models,
                sessionFactory: AmplifyURLSessionFactory()
            ))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models,
                                                       configuration: .custom(syncMaxRecords: 100)))
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

    func startAmplify(_ completion: BasicClosure? = nil) throws {
        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)

        DispatchQueue.global().async {
            do {
                try Amplify.configure(amplifyConfig)
                completion?()
            } catch {
                XCTFail(String(describing: error))
            }
        }
    }

    func startAmplifyAndWaitForSync() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) async throws {
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

        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)
        try Amplify.configure(amplifyConfig)
        try await Amplify.DataStore.start()
        await fulfillment(of: [eventReceived], timeout: 100)
    }
}
