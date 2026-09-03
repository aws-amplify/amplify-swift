//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class ASFCognitoTests: XCTestCase, @unchecked Sendable {

    func testTimeZoneOffetNegative() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: -25_200)
        XCTAssertEqual("-07:00", timezoneOffet)
    }

    func testTimeZoneOffetPositive() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: 25_200)
        XCTAssertEqual("+07:00", timezoneOffet)
    }

    func testTimeZoneOffetZero() {
        let asf = CognitoUserPoolASF()
        let timezoneOffet = asf.timeZoneOffet(seconds: 0)
        XCTAssertEqual("+00:00", timezoneOffet)
    }
}
