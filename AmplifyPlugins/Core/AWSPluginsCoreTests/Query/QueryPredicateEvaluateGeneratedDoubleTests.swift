//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
//swiftlint:disable type_body_length
//swiftlint:disable file_length
//swiftlint:disable type_name
class QueryPredicateEvaluateGeneratedDoubleTests: XCTestCase {
    func testDouble1_1notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3notEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3notEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3notEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ne(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3equalsDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3equalsDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3equalsDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.eq(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3lessOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3lessOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.le(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3lessThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.lt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3greaterOrEqualDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3greaterOrEqualDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.ge(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2_1greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3_1greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3.1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(1)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble2greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(2)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble1_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 1.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3greaterThanDouble2_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 2.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssert(evaluation)
    }

    func testDouble3greaterThanDouble3_1() throws {
       let predicate = QPredGen.keys.myDouble.gt(3)
       var instance = QPredGen(name: "test")
       instance.myDouble = 3.1

       let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

       XCTAssertFalse(evaluation)
    }

}
