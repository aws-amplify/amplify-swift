//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin

class AWSS3StoragePluginBaseConfigTests: XCTestCase {

    func testThrowsOnMissingConfig() throws {
        let plugin = AWSS3StoragePlugin()
        try Amplify.add(plugin: plugin)

        let categoryConfig = StorageCategoryConfiguration(plugins: ["NonExistentPlugin": true])
        let amplifyConfig = AmplifyConfiguration(storage: categoryConfig)
        do {
            try Amplify.configure(amplifyConfig)
            XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
        } catch {
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Should have thrown a pluginConfigurationError if not supplied with a plugin-specific config.")
                return
            }
        }
    }

    override func tearDown() async throws {
        // Need this to avoid plugin already configured exception in the subsequent tests
        await Amplify.reset()
    }

}
