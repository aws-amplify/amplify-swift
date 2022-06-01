//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable type_name
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

    func testDouble1_1notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble2_1notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble3_1notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        let instance = QPredGen(name: "test")

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

    func testDouble1notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble2notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble3notEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3notEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3notEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3notEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble1_1equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        let instance = QPredGen(name: "test")

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

    func testDouble2_1equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        let instance = QPredGen(name: "test")

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

    func testDouble3_1equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

    func testDouble1equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        let instance = QPredGen(name: "test")

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

    func testDouble2equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        let instance = QPredGen(name: "test")

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

    func testDouble3equalsDouble1() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3equalsDouble2() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3equalsDouble3() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3equalsDouble() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        let instance = QPredGen(name: "test")

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

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
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

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
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

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3greaterOrEqualDouble1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble2() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualDouble3() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3greaterOrEqualDouble() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        let instance = QPredGen(name: "test")

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

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
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

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble1_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble2_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble3_1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3greaterThanDouble1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble2() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble3() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanDouble() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with0_0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0.0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with1_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with1_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with3() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with3_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with3_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with4() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenDouble3_1with() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with0_0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0.0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenDouble3with1_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenDouble3with2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenDouble3with1_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenDouble3with3() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenDouble3with3_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with3_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with4() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenDouble3with() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
