//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class AWSAPICategoryPluginConfigureTests: XCTestCase {

    func testConfigureSuccessForNilConfiguration() throws {
        let storageEngine = MockStorageEngineBehavior()
        let dataStorePublisher = DataStorePublisher()
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration(),
                                        storageEngine: storageEngine,
                                        dataStorePublisher: dataStorePublisher,
                                        validAPIPluginKey: "MockAPICategoryPlugin",
                                        validAuthPluginKey: "MockAuthCategoryPlugin")
        do {
            try plugin.configure(using: nil)

        } catch {
            XCTFail("DataStore configuration should not fail with nil configuration. \(error)")
        }
    }
}
