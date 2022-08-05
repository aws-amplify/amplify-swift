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

// swiftlint:disable type_name
class QueryPredicateEvaluateGeneratedIntDoubleTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: QPredGen.self)
    }

    func testbetweenInt1betweenDouble3_1with0() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myInt = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenDouble3_1with1() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3_1with2() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3_1with3() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3_1with4() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        var instance = QPredGen(name: "test")
        instance.myInt = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenDouble3_1with() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3.1)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenDouble3with0() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 0

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenDouble3with1() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 1

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3with2() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 2

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3with3() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 3

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenInt1betweenDouble3with4() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        var instance = QPredGen(name: "test")
        instance.myInt = 4

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenInt1betweenDouble3with() throws {
        let predicate = QPredGen.keys.myInt.between(start: 1, end: 3)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
