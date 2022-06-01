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
class QueryPredicateEvaluateGeneratedDoubleIntTests: XCTestCase {
    func testDouble1_1notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3notEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3notEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3notEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3notEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ne(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3equalsInt1() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3equalsInt2() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3equalsInt3() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3equalsInt() throws {
        let predicate = QPredGen.keys.myDouble.eq(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.le(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3_1lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3lessThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3lessThanInt() throws {
        let predicate = QPredGen.keys.myDouble.lt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble3greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myDouble.ge(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1_1greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1_1greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(1.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2_1greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2_1greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(2.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3_1greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble1greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble1greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble2greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testDouble2greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanInt1() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanInt2() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanInt3() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testDouble3greaterThanInt() throws {
        let predicate = QPredGen.keys.myDouble.gt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with0_0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0.0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with1_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with1_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with3() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with3_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with3_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with4() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1_1betweenInt3with() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1.1, end: 3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with0_0() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 0.0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenInt3with1_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenInt3with2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenInt3with1_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 1.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenInt3with3() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenDouble1betweenInt3with3_1() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with3_2() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 3.2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with4() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myDouble = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenDouble1betweenInt3with() throws {
        let predicate = QPredGen.keys.myDouble.between(start: 1, end: 3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
