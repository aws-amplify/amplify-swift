//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSLocationGeoPlugin

// swiftlint:disable:next type_name
class AWSLocationGeoPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSLocationGeoPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
