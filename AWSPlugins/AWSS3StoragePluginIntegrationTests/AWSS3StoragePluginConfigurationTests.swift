//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3
class AWSS3StoragePluginConfigurationTests: AWSS3StoragePluginTestBase {

    func testConfigureWithIncorrectDefaultAccessLevelValueShouldThrow() {
        Amplify.reset()

        let bucketJSONValue = JSONValue.init(stringLiteral: bucket)
        let regionJSONValue = JSONValue.init(stringLiteral: region)
        let defaultAccessLevelJSONValue = JSONValue.init(stringLiteral: "public123")

        let storagePluginConfig = JSONValue.init(dictionaryLiteral: ("Bucket", bucketJSONValue),
                                                 ("Region", regionJSONValue),
                                                 ("DefaultAccessLevel", defaultAccessLevelJSONValue))

        let storageConfig = StorageCategoryConfiguration(
            plugins: ["AWSS3StoragePlugin": storagePluginConfig]
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
