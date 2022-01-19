//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin


class SyncEngineIntegrationTestBase: DataStoreTestBase {
    
    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {
        guard let url = Bundle.module.url(forResource: forResource, withExtension: "json") else {
            throw "Could not retrieve configuration file: \(forResource)"
        }
        let data = try Data(contentsOf: url)
        return try AmplifyConfiguration.decodeAmplifyConfiguration(from: data)
    }
    
    static let amplifyConfigurationFile = "AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration"

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

    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) {

        continueAfterFailure = false

        Amplify.reset()
        sleep(2)
        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    func stopDataStore() {
        let stopped = expectation(description: "DataStore stopped")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                stopped.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopped], timeout: 2)
    }

    func clearDataStore() {
        let cleared = expectation(description: "DataStore cleared")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                cleared.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [cleared], timeout: 2)
    }

    func startAmplify() throws {
        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
            forResource: Self.amplifyConfigurationFile)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func startAmplifyAndWaitForSync() throws {
        try startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() throws {
        try startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) throws {
        let eventReceived = expectation(description: "DataStore \(eventName) event")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: eventName) { _ in
            eventReceived.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try startAmplify()
        Amplify.DataStore.start { result in
            if case .failure(let error) = result {
                XCTFail("\(error)")
            }
        }

        wait(for: [eventReceived], timeout: 100.0)
    }

}
