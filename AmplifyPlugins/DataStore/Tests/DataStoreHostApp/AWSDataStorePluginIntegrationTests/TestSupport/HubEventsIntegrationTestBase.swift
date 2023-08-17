//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSAPIPlugin
import AWSPluginsCore
#if !os(watchOS)
@testable import DataStoreHostApp
#endif
@testable import Amplify
@testable import AWSDataStorePlugin

class HubEventsIntegrationTestBase: XCTestCase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration"

    static let networkTimeout = TimeInterval(180)
    let networkTimeout = HubEventsIntegrationTestBase.networkTimeout

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
        try await Amplify.DataStore.clear()
        await Amplify.reset()
    }

    func configureAmplify(withModels models: AmplifyModelRegistration) throws {
        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)

        try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
        try Amplify.add(plugin: AWSAPIPlugin(
            modelRegistration: models,
            sessionFactory: AmplifyURLSessionFactory()
        ))
        try Amplify.configure(amplifyConfig)
    }

    func startAmplify(withModels models: AmplifyModelRegistration) async {
        do {
            try configureAmplify(withModels: models)
            try await Amplify.DataStore.start()
        } catch {
            XCTFail(String(describing: error))
        }
    }
}
