//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin
import AWSS3
class AWSS3StoragePluginConfigurationTests: XCTestCase {

    /// Given: awss3StoragePlugin configuration with incorrect DefaultAccessLevel value
    /// When: Configure Amplify
    /// Then: The call throws a PluginError.pluginConfigurationError
    func testConfigureWithIncorrectDefaultAccessLevelValueShouldThrow() async {
        await Amplify.reset()

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "awsS3StoragePlugin": [
                    "bucket": "bucket",
                    "region": "us-west-2",
                    "defaultAccessLevel": "guest123"
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
            guard case StorageError.configuration = error else {
                XCTFail("Expected PluginError pluginConfigurationError, got: \(error)")
                return
            }
        }
    }
}
