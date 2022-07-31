//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class ASFUIDeviceInfoTests: XCTestCase {

    func testSuccess() {
        let asf = ASFUIDeviceInfo(id: "mockID")
        let deviceFingerPrint = asf.deviceInfo()
        XCTAssertNotNil(deviceFingerPrint)
    }
}
