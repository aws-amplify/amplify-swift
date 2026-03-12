//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginConfigurationTests: XCTestCase {

    func testConfiguration() {
        let storagePlugin = AWSS3StoragePlugin(configuration: .prefixResolver(MockPrefixResolver()))
        XCTAssertNotNil(storagePlugin.storageConfiguration.prefixResolver as? MockPrefixResolver)
    }

    /// Given: AWSS3StoragePluginConfiguration with progressStallTimeoutInterval
    /// When: Configuration is created
    /// Then: progressStallTimeoutInterval is stored correctly
    func testProgressStallTimeoutInterval_configuration() {
        let config = AWSS3StoragePluginConfiguration(progressStallTimeoutInterval: 60)
        XCTAssertEqual(config.progressStallTimeoutInterval, 60)

        let defaultConfig = AWSS3StoragePluginConfiguration()
        XCTAssertEqual(defaultConfig.progressStallTimeoutInterval, 0)
    }

    struct MockPrefixResolver: AWSS3PluginPrefixResolver {
        func resolvePrefix(
            for accessLevel: StorageAccessLevel,
            targetIdentityId: String?
        ) async throws -> String {
            ""
        }
    }
}
