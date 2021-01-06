//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSCognitoAuthPlugin

// swiftlint:disable:next type_name
class AWSCognitoAuthPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSCognitoAuthPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
