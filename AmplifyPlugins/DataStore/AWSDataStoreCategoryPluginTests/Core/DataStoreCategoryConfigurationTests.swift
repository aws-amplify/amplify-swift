//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSDataStorePlugin

class AWSDataStorePluginConfigurationTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    func testDoesNotThrowOnMissingConfig() throws {
        let plugin = AWSDataStorePlugin(modelRegistration: TestModelRegistration())
        try Amplify.add(plugin: plugin)

        let categoryConfig = DataStoreCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(dataStore: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Should not throw even if not supplied with a plugin-specific config.")
        }
    }

}
