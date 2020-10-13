//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class HubEventsIntegrationTestBase: XCTestCase {

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

    func startAmplify() {
        let bundle = Bundle(for: type(of: self))
        guard let configFile = bundle.url(forResource: "amplifyconfiguration", withExtension: "json") else {
            XCTFail("Could not get URL for amplifyconfiguration.json from \(bundle)")
            return
        }

        do {
            let configData = try Data(contentsOf: configFile)
            let amplifyConfig = try JSONDecoder().decode(AmplifyConfiguration.self, from: configData)
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: TestModelRegistration()))
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: TestModelRegistration()))
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        sleep(1)
        print("Amplify reset")
        storageAdapter.delete(untypedModelType: ModelSyncMetadata.self, withId: "Post") { _ in }
        storageAdapter.delete(untypedModelType: ModelSyncMetadata.self, withId: "Comment") { _ in }
        Amplify.reset()
    }
}
