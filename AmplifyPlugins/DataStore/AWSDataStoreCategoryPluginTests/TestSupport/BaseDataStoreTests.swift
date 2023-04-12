//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/// Base class for Local data store tests
class BaseDataStoreTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var syncEngine: RemoteSyncEngineBehavior!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var dataStorePlugin: AWSDataStorePlugin!

    // MARK: - Lifecycle

    override func tearDown() {
        Amplify.reset()
        sleep(1)
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        Amplify.Logging.logLevel = .warn

        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
            try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

            syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                                  dataStoreConfiguration: .default)
            storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
            storageEngine.syncEngine = syncEngine
        } catch {
            XCTFail(String(describing: error))
            return
        }
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _  throws in
            return self.storageEngine
        }
        let dataStorePublisher = DataStorePublisher()
        dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
        ])

        // Since these tests use syncable models, we have to set up an API category also
        let apiConfig = APICategoryConfiguration(plugins: ["MockAPICategoryPlugin": true])
        let apiPlugin = MockAPICategoryPlugin()

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
            try Amplify.configure(amplifyConfig)
            XCTAssertEqual(dataStorePlugin.dispatchedModelSyncedEvents.count, ModelRegistry.modelSchemas.count)
            Amplify.DataStore.start(completion: {_ in})
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    // MARK: - Utilities

    func populateData<M: Model>(_ models: [M]) {
        let expectation = expectation(description: "Data is populated")
        expectation.expectedFulfillmentCount = models.count
        for model in models {
            Task {
                self.storageAdapter.save(model) { result in
                    defer { expectation.fulfill() }
                    if case .failure(let error) = result {
                        XCTFail(error.errorDescription)
                    }
                }
            }
        }
        wait(for: [expectation], timeout: 5)
    }

}
