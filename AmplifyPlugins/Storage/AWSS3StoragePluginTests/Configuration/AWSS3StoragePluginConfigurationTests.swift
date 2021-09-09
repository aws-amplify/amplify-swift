//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin

class AWSS3StoragePluginConfigurationTests: XCTestCase {

    func testConfiguration() {
        let storagePlugin = AWSS3StoragePlugin(configuration: .prefixResolver(MockPrefixResolver()))
        XCTAssertNotNil(storagePlugin.storageConfiguration.prefixResolver as? MockPrefixResolver)
    }

    struct MockPrefixResolver: AWSS3PluginPrefixResolver {
        func resolvePrefix(for accessLevel: StorageAccessLevel,
                           targetIdentityId: String?) -> Result<String, StorageError> {
            .success("")
        }
    }
}
