//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAPIPlugin
import XCTest

// swiftlint:disable:next type_name
class AWSAPICategoryPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSAPIPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
