//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite
import CwlPreconditionTesting

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

/// Tests Amplify behavior around DataStore's dependency on the API category
class APICategoryDependencyTests: XCTestCase {

    // Tests in this class will directly access the database to validate persistent queue behavior
    var storageAdapter: SQLiteStorageEngineAdapter!

    /// - Given: An Amplify system configured with a DataStore but no API category
    /// - When:
    ///    - I invoke `save` on a non-syncable model
    /// - Then:
    ///    - The operation succeeds
    func testNonSyncableWithoutAPICategorySucceeds() throws {
        try setUpWithAPI()

        let model = MockUnsynced()

        let modelSaved = expectation(description: "Model saved")
        Amplify.DataStore.save(model) { _ in modelSaved.fulfill() }
        wait(for: [modelSaved], timeout: 1.0)
    }

    /// - Given: An Amplify system configured with a DataStore but no API category
    /// - When:
    ///    - I invoke `save` on a syncable model
    /// - Then:
    ///    - Amplify crashes
    func testSyncWithoutAPICategoryCrashes() throws {
        try setUpWithoutAPI()

        let model = MockSynced()

        let exception: BadInstructionException? = catchBadInstruction {
            Amplify.DataStore.save(model) { _ in }
        }
        XCTAssertNotNil(exception)
    }

}

// MARK: - Setup

extension APICategoryDependencyTests {
    private func setUpCore() throws -> AmplifyConfiguration {
        Amplify.reset()
        ModelRegistry.register(modelType: MockSynced.self)
        ModelRegistry.register(modelType: MockUnsynced.self)

        let connection = try Connection(.inMemory)
        storageAdapter = SQLiteStorageEngineAdapter(connection: connection)

        let syncEngineFactory: CloudSyncEngineBehavior.Factory? = { CloudSyncEngine(storageEngine: $0) }
        let storageEngine = StorageEngine(adapter: storageAdapter, syncEngineFactory: syncEngineFactory)

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStoreCategoryPlugin(storageEngine: storageEngine,
                                                         dataStorePublisher: dataStorePublisher)
        try Amplify.add(plugin: dataStorePlugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)

        return amplifyConfig
    }

    private func setUpAPICategory(config: AmplifyConfiguration) throws -> AmplifyConfiguration {
        let apiPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: apiPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: config.dataStore)

        return amplifyConfig
    }

    private func setUpWithAPI() throws {
        let configWithoutAPI = try setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

    private func setUpWithoutAPI() throws {
        let configWithoutAPI = try setUpCore()
        try Amplify.configure(configWithoutAPI)
    }

}
