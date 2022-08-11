//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// Tests Amplify behavior around DataStore's dependency on the API category
class APICategoryDependencyTests: XCTestCase {

    // Tests in this class will directly access the database to validate persistent queue behavior
    var storageAdapter: SQLiteStorageEngineAdapter!

    /// - Given: An Amplify system configured with a DataStore but no API category
    /// - When:
    ///    - I invoke `save` on a non-syncable model
    /// - Then:
    ///    - The operation succeeds
    func testNonSyncableWithoutAPICategorySucceeds() async throws {
        try await setUpWithAPI()
        let model = MockUnsynced()
        _ = try await Amplify.DataStore.save(model)
    }

    /// **NOTE:** We can't put in a meaningful test for this condition because the first call to the unconfigured API
    /// category happens outside of the block being protected by `catchBadInstruction`. This test can be manually
    /// run simply by uncommenting it.
    ///
    /// - Given: An Amplify system configured with a DataStore but no API category
    /// - When:
    ///    - I invoke `save` on a syncable model
    /// - Then:
    ///    - Amplify crashes
//    func testSyncWithoutAPICategoryCrashes() throws {
//
//        try setUpWithoutAPI()
//
//        let model = MockSynced()
//
//        let exception: BadInstructionException? = catchBadInstruction {
//            Amplify.DataStore.save(model) { _ in }
//        }
//        XCTAssertNotNil(exception)
//    }

}

// MARK: - Setup

extension APICategoryDependencyTests {
    private func setUpCore() async throws -> AmplifyConfiguration {
        await Amplify.reset()

        let connection = try Connection(.inMemory)
        storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)

        let syncEngine = try RemoteSyncEngine(storageAdapter: storageAdapter,
                                              dataStoreConfiguration: .default)
        let validAPIPluginKey = "MockAPICategoryPlugin"
        let validAuthPluginKey = "MockAuthCategoryPlugin"
        let storageEngine = StorageEngine(storageAdapter: storageAdapter,
                                          dataStoreConfiguration: .default,
                                          syncEngine: syncEngine,
                                          validAPIPluginKey: validAPIPluginKey,
                                          validAuthPluginKey: validAuthPluginKey)
        let storageEngineBehaviorFactory: StorageEngineBehaviorFactory = {_, _, _, _, _, _  throws in
            return storageEngine
        }

        let dataStorePublisher = DataStorePublisher()
        let dataStorePlugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                                 storageEngineBehaviorFactory: storageEngineBehaviorFactory,
                                                 dataStorePublisher: dataStorePublisher,
                                                 validAPIPluginKey: validAPIPluginKey,
                                                 validAuthPluginKey: validAuthPluginKey)
        try Amplify.add(plugin: dataStorePlugin)

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStorePlugin": true
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

    private func setUpWithAPI() async throws {
        let configWithoutAPI = try await setUpCore()
        let configWithAPI = try setUpAPICategory(config: configWithoutAPI)
        try Amplify.configure(configWithAPI)
    }

    private func setUpWithoutAPI() async throws {
        let configWithoutAPI = try await setUpCore()
        try Amplify.configure(configWithoutAPI)
    }

}
