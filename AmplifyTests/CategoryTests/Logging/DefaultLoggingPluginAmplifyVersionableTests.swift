//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

// swiftlint:disable:next type_name
class DefaultLoggingPluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSUnifiedLoggingPlugin()
        XCTAssertNotNil(plugin.version)
    }

}
