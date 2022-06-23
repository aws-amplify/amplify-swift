//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSAPIPlugin
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
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

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func startAmplify(withModels models: AmplifyModelRegistration) {
        do {
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: Self.amplifyConfigurationFile)

            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.configure(amplifyConfig)
            Amplify.DataStore.start { result in
                if case .failure(let error) = result {
                    XCTFail("\(error)")
                }
            }
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() async throws {
        sleep(1)
        print("Amplify reset")
        storageAdapter.delete(untypedModelType: ModelSyncMetadata.self, withId: "Post") { _ in }
        storageAdapter.delete(untypedModelType: ModelSyncMetadata.self, withId: "Comment") { _ in }
        await Amplify.reset()
    }
}
