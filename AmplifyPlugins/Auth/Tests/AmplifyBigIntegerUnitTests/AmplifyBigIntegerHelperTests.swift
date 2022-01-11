//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyBigInteger

final class AmplifyBigIntegerHelperTests: XCTestCase {

    func testHex236() {
        let num = AmplifyBigInt(236)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "EC")
    }

    func testHexNegative236() {
        let num = AmplifyBigInt(-236)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FF14")
    }

    func testHex20() {
        let num = AmplifyBigInt(20)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "14")
    }

    func testHexNegative20() {
        let num = AmplifyBigInt(-20)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FFEC")
    }

    func testHexNegative200() {
        let num = AmplifyBigInt(-200)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FF38")
    }

    func testHex56() {
        let num = AmplifyBigInt(56)
        let result = AmplifyBigIntHelper.getSignedData(num: num)

        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "38")
    }

}
