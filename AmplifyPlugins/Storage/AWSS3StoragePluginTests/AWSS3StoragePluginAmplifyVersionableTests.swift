//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSS3StoragePlugin

// swiftlint:disable:next type_name
class AWSS3StoragePluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSS3StoragePlugin()
        XCTAssertNotNil(plugin.version)
    }

}
