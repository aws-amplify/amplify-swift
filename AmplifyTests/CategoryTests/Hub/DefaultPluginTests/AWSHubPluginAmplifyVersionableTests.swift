//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

class AWSHubPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSHubPlugin()
        XCTAssertNotNil(plugin.version)
    }
}
