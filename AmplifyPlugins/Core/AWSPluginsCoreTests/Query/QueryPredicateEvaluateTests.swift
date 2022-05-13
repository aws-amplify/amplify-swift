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
class QueryPredicateEvaluateTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: QPredGen.self)
    }
    func testMultiGroupAndPlusOr() throws {
        let predicate = (QPredGen.keys.myBool.eq(true) && QPredGen.keys.name.eq("NotMatch")
                                                       && QPredGen.keys.myString.eq("NotMatch"))
                        || (QPredGen.keys.myInt.gt(1) && QPredGen.keys.myInt.le(10))
                        || (QPredGen.keys.myDouble.gt(1) && QPredGen.keys.myDouble.le(10))
        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myInt = 2
        instance.myDouble = 5

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testMultiAndPlusOr() throws {
        let predicate = (QPredGen.keys.name.eq("test") && QPredGen.keys.myString.eq("NotMatch"))
             || QPredGen.keys.myInt.eq(2)
        var instance = QPredGen(name: "test")
        instance.myString = "doe"
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testOrPlusMultiAnd() throws {
        let predicate = QPredGen.keys.myInt.eq(2) ||
            (QPredGen.keys.myBool.eq(true) && QPredGen.keys.name.eq("NotMatch")
                                           || QPredGen.keys.myString.eq("NotMatch"))

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testMultiOrPlusAnd() throws {
        let predicate = (QPredGen.keys.myBool.eq(true) || QPredGen.keys.myString.eq("NotMatch"))
        && QPredGen.keys.myInt.eq(3)

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myString = "test"
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBoolorStringWithAllAnd_false() throws {
        let predicate = (QPredGen.keys.myBool.eq(true) && QPredGen.keys.name.eq("test"))
        && QPredGen.keys.myInt.eq(3)

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
    func testBoolorStringWithAllAnd_true() throws {
        let predicate = (QPredGen.keys.myBool.eq(true) && QPredGen.keys.name.eq("test"))
        && QPredGen.keys.myInt.eq(2)

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }
    func testBoolorStringWithAllOr_true() throws {
        let predicate = (QPredGen.keys.myBool.eq(false) || QPredGen.keys.myString.eq("NotMatch"))
        || QPredGen.keys.myInt.eq(2)

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myString = "test"
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }
    func testBoolorStringWithAllOr_false() throws {
        let predicate = (QPredGen.keys.myBool.eq(false) || QPredGen.keys.myString.eq("NotMatch"))
        || QPredGen.keys.myInt.eq(3)

        var instance = QPredGen(name: "test")
        instance.myBool = true
        instance.myString = "test"
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
    func testBetweenIntStart() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 10)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }
    func testBetweenIntBeyondEnd() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 10)
        var instance = QPredGen(name: "test")
        instance.myInt = 11

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
    func testBetweenIntEnd() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 10)
        var instance = QPredGen(name: "test")
        instance.myInt = 10

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }
    func testConstantall() throws {
        let predicate = QueryPredicateConstant.all
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }
}
