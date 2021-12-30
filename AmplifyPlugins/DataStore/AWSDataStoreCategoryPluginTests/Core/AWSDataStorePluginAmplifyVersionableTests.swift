//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSDataStorePlugin
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AWSDataStorePluginAmplifyVersionableTests: XCTestCase {

    func testVersionExists() {
        let plugin = AWSDataStorePlugin(modelRegistration: AmplifyModels())
        XCTAssertNotNil(plugin.version)
    }

}
