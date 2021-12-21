//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyBigInteger

final class AmplifyBigIntDecimalTests: XCTestCase {
    
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
    
    func testAddition() {
        let number1 = AmplifyBigInt(23)
        let number2 = AmplifyBigInt(67)
        
        let result = number1 + number2
        XCTAssertEqual(result.asString, "90")
    }
    
    func testSubstraction() {
        let number1 = AmplifyBigInt(23)
        let number2 = AmplifyBigInt(67)
        
        let result = number1 - number2
        XCTAssertEqual(result.asString, "-44")
    }
}


