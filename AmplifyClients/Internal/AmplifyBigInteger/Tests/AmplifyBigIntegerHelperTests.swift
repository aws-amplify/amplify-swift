//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyBigInteger
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AmplifyBigIntegerHelperTests: XCTestCase, @unchecked Sendable {

    /// - Given: the integer 236
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "EC": a positive number keeps its magnitude
    func testHex236() {
        let num = AmplifyBigInt(236)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "EC")
    }

    /// - Given: the integer -236
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "FF14": a negative number comes out in two's complement
    func testHexNegative236() {
        let num = AmplifyBigInt(-236)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FF14")
    }

    /// - Given: the integer 20
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "14": a positive number keeps its magnitude
    func testHex20() {
        let num = AmplifyBigInt(20)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "14")
    }

    /// - Given: the integer -20
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "FFEC": a negative number comes out in two's complement
    func testHexNegative20() {
        let num = AmplifyBigInt(-20)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FFEC")
    }

    /// - Given: the integer -200
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "FF38": a negative number comes out in two's complement
    func testHexNegative200() {
        let num = AmplifyBigInt(-200)
        let result = AmplifyBigIntHelper.getSignedData(num: num)
        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "FF38")
    }

    /// - Given: the integer 56
    /// - When: `AmplifyBigIntHelper.getSignedData(num:)` encodes it, and the bytes are read back as an unsigned
    ///   integer
    /// - Then:
    ///    - that integer prints in hexadecimal as "38": a positive number keeps its magnitude
    func testHex56() {
        let num = AmplifyBigInt(56)
        let result = AmplifyBigIntHelper.getSignedData(num: num)

        let resultNum = AmplifyBigInt(unsignedData: result)
        XCTAssertEqual(resultNum.asString(radix: 16), "38")
    }

}
