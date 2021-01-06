//
// Copyright 2018-2021 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPICategoryPlugin

// swiftlint:disable:next type_name
class AWSAPICategoryPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSAPIPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
