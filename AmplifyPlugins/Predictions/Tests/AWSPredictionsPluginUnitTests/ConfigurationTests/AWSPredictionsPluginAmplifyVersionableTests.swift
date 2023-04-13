//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPredictionsPlugin

// swiftlint:disable:next type_name
class AWSPredictionsPluginAmplifyVersionableTests: XCTestCase {
    func testVersionExists() {
        let plugin = AWSPredictionsPlugin()
        XCTAssertNotNil(plugin.version)
    }
}
