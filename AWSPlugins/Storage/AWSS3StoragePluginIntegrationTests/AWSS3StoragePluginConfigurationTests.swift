//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import Amplify
import AWSS3StoragePlugin
import AWSS3
class AWSS3StoragePluginConfigurationTests: AWSS3StoragePluginTestBase {

    /// Given:  AWSS3StoragePlugin configuration with incorrect DefaultAccessLevel value
    /// When: Configure Amplify
    /// Then: The call throws a PluginError.pluginConfigurationError
    func testConfigureWithIncorrectDefaultAccessLevelValueShouldThrow() {
        Amplify.reset()

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "AWSS3StoragePlugin": [
                    "Bucket": bucket,
                    "Region": region,
                    "DefaultAccessLevel": "public123"
                ]
            ]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        do {
            try Amplify.add(plugin: AWSS3StoragePlugin())
        } catch {
            XCTFail("Failed to add plugin before configuring")
        }

        XCTAssertThrowsError(try Amplify.configure(amplifyConfig)) { error in
            guard case PluginError.pluginConfigurationError = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
        }
    }
}
