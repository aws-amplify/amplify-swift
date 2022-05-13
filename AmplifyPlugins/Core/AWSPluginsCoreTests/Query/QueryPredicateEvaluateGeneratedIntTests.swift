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
class QueryPredicateEvaluateGeneratedIntBetweenTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: QPredGen.self)
    }

    func testInt1notEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ne(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1notEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ne(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1notEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ne(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1notEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ne(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2notEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ne(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2notEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ne(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2notEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ne(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2notEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ne(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3notEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ne(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3notEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ne(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3notEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ne(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3notEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ne(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1equalsInt1() throws {
        let predicate = QPredGen.keys.myInt.eq(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1equalsInt2() throws {
        let predicate = QPredGen.keys.myInt.eq(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1equalsInt3() throws {
        let predicate = QPredGen.keys.myInt.eq(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1equalsInt() throws {
        let predicate = QPredGen.keys.myInt.eq(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2equalsInt1() throws {
        let predicate = QPredGen.keys.myInt.eq(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2equalsInt2() throws {
        let predicate = QPredGen.keys.myInt.eq(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2equalsInt3() throws {
        let predicate = QPredGen.keys.myInt.eq(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2equalsInt() throws {
        let predicate = QPredGen.keys.myInt.eq(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3equalsInt1() throws {
        let predicate = QPredGen.keys.myInt.eq(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3equalsInt2() throws {
        let predicate = QPredGen.keys.myInt.eq(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3equalsInt3() throws {
        let predicate = QPredGen.keys.myInt.eq(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3equalsInt() throws {
        let predicate = QPredGen.keys.myInt.eq(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.le(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.le(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.le(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.le(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.le(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.le(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.le(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.le(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3lessOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.le(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3lessOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.le(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3lessOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.le(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3lessOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.le(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessThanInt1() throws {
        let predicate = QPredGen.keys.myInt.lt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessThanInt2() throws {
        let predicate = QPredGen.keys.myInt.lt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessThanInt3() throws {
        let predicate = QPredGen.keys.myInt.lt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1lessThanInt() throws {
        let predicate = QPredGen.keys.myInt.lt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2lessThanInt1() throws {
        let predicate = QPredGen.keys.myInt.lt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2lessThanInt2() throws {
        let predicate = QPredGen.keys.myInt.lt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2lessThanInt3() throws {
        let predicate = QPredGen.keys.myInt.lt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2lessThanInt() throws {
        let predicate = QPredGen.keys.myInt.lt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3lessThanInt1() throws {
        let predicate = QPredGen.keys.myInt.lt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3lessThanInt2() throws {
        let predicate = QPredGen.keys.myInt.lt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3lessThanInt3() throws {
        let predicate = QPredGen.keys.myInt.lt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3lessThanInt() throws {
        let predicate = QPredGen.keys.myInt.lt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ge(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ge(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ge(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ge(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ge(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ge(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ge(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ge(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterOrEqualInt1() throws {
        let predicate = QPredGen.keys.myInt.ge(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterOrEqualInt2() throws {
        let predicate = QPredGen.keys.myInt.ge(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterOrEqualInt3() throws {
        let predicate = QPredGen.keys.myInt.ge(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt3greaterOrEqualInt() throws {
        let predicate = QPredGen.keys.myInt.ge(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1greaterThanInt1() throws {
        let predicate = QPredGen.keys.myInt.gt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt1greaterThanInt2() throws {
        let predicate = QPredGen.keys.myInt.gt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1greaterThanInt3() throws {
        let predicate = QPredGen.keys.myInt.gt(1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt1greaterThanInt() throws {
        let predicate = QPredGen.keys.myInt.gt(1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2greaterThanInt1() throws {
        let predicate = QPredGen.keys.myInt.gt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2greaterThanInt2() throws {
        let predicate = QPredGen.keys.myInt.gt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt2greaterThanInt3() throws {
        let predicate = QPredGen.keys.myInt.gt(2)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testInt2greaterThanInt() throws {
        let predicate = QPredGen.keys.myInt.gt(2)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterThanInt1() throws {
        let predicate = QPredGen.keys.myInt.gt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterThanInt2() throws {
        let predicate = QPredGen.keys.myInt.gt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterThanInt3() throws {
        let predicate = QPredGen.keys.myInt.gt(3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testInt3greaterThanInt() throws {
        let predicate = QPredGen.keys.myInt.gt(3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenInt3with0() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenInt3with1() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenInt3with2() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenInt3with3() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenInt3with4() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenInt3with() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
