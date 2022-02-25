//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class SyncEngineFlutterIntegrationTestBase: XCTestCase {
    
    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = SyncEngineFlutterIntegrationTestBase.networkTimeout

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
    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        do {
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: TestFlutterModelRegistration()))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: TestFlutterModelRegistration()))
        } catch {
            XCTFail(String(describing: error))
            return
        }
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

    func startAmplifyAndWaitForSync() throws {
        let syncStarted = expectation(description: "Sync started")
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
            syncStarted.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try startAmplify {
            plugin.start { result in
                if case .failure(let error) = result {
                    XCTFail("\(error)")
                }
            }
        }

        wait(for: [syncStarted], timeout: 100.0)
    }

}
