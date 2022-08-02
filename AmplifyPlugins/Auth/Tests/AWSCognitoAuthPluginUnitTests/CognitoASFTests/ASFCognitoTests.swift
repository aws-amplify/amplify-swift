//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class ASFCognitoTests: XCTestCase {

    func testTimeZoneOffetNegative() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: -25200)
        XCTAssertEqual("-07:00", timezoneOffet)
    }

    func testTimeZoneOffetPositive() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: 25200)
        XCTAssertEqual("+07:00", timezoneOffet)
    }

    func testTimeZoneOffetZero() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: 0)
        XCTAssertEqual("+00:00", timezoneOffet)
    }
}
