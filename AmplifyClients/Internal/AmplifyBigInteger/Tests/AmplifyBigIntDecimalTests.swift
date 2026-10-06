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
final class AmplifyBigIntDecimalTests: XCTestCase, @unchecked Sendable {

    /// - Given: the decimal strings "2", "3" and "-23233"
    /// - When: each is parsed with radix 10 and printed with `asString`
    /// - Then:
    ///    - each prints as the string it was parsed from
    func testConversionDecimal() throws {
        guard let firstInt = AmplifyBigInt("2", radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        guard let secondInt = AmplifyBigInt("3", radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        guard let thirdInt = AmplifyBigInt("-23233", radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        XCTAssertEqual("2", firstInt.asString)
        XCTAssertEqual("3", secondInt.asString)
        XCTAssertEqual("-23233", thirdInt.asString)
    }

    /// - Given: a positive 144-digit decimal string
    /// - When: it is parsed with radix 10 and printed with `asString`
    /// - Then:
    ///    - it prints as the same string
    func testConversionLargeDecimal() throws {
        let largeNumber =
        "23842389473298759348759834759834759834759834759834759834759834759347895734584567" +
        "5467498576498764589674598675409785907860597856097856092362534625"
        guard let largeInt = AmplifyBigInt(largeNumber, radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        XCTAssertEqual(largeNumber, largeInt.asString)
    }

    /// - Given: a negative 144-digit decimal string
    /// - When: it is parsed with radix 10 and printed with `asString`
    /// - Then:
    ///    - it prints as the same string, sign included
    func testConversionLargeNegativeDecimal() throws {
        let largeNumber =
        "-23842389473298759348759834759834759834759834759834759834759834759347895734584567" +
        "5467498576498764589674598675409785907860597856097856092362534625"
        guard let largeInt = AmplifyBigInt(largeNumber, radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        XCTAssertEqual(largeNumber, largeInt.asString)
    }

    /// - Given: a negative 225-digit decimal string
    /// - When: it is parsed with radix 10 and printed with `asString`
    /// - Then:
    ///    - it prints as the same string, sign included
    func testConversionLargeNegativeDecimal_2() throws {
        let largeNumber =
        "-23842389473298759348759834759834759834759834759834759834759834759347895734584567" +
        "034850934850943856094865965967586785785785765987659786598569785689756978655867856" +
        "5467498576498764589674598675409785907860597856097856092362534625"
        guard let largeInt = AmplifyBigInt(largeNumber, radix: 10) else {
            XCTFail("Could not create integer")
            return
        }
        XCTAssertEqual(largeNumber, largeInt.asString)
    }

    /// - Given: the integers 23 and 67
    /// - When: they are added
    /// - Then:
    ///    - the sum prints as "90"
    func testAddition() {
        let number1 = AmplifyBigInt(23)
        let number2 = AmplifyBigInt(67)

        let result = number1 + number2
        XCTAssertEqual(result.asString, "90")
    }

    /// - Given: the integers 23 and 67
    /// - When: 67 is subtracted from 23
    /// - Then:
    ///    - the difference prints as "-44"
    func testSubstraction() {
        let number1 = AmplifyBigInt(23)
        let number2 = AmplifyBigInt(67)

        let result = number1 - number2
        XCTAssertEqual(result.asString, "-44")
    }
}
