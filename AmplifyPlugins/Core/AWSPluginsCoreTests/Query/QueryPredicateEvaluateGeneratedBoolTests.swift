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
class QueryPredicateEvaluateGeneratedBoolTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: QPredGen.self)
    }

    func testBooltruenotEqualBooltrue() throws {
        let predicate = QPredGen.keys.myBool.ne(true)
        var instance = QPredGen(name: "test")
        instance.myBool = true

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBooltruenotEqualBoolfalse() throws {
        let predicate = QPredGen.keys.myBool.ne(true)
        var instance = QPredGen(name: "test")
        instance.myBool = false

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testBooltruenotEqualBool() throws {
        let predicate = QPredGen.keys.myBool.ne(true)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBoolfalsenotEqualBooltrue() throws {
        let predicate = QPredGen.keys.myBool.ne(false)
        var instance = QPredGen(name: "test")
        instance.myBool = true

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testBoolfalsenotEqualBoolfalse() throws {
        let predicate = QPredGen.keys.myBool.ne(false)
        var instance = QPredGen(name: "test")
        instance.myBool = false

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBoolfalsenotEqualBool() throws {
        let predicate = QPredGen.keys.myBool.ne(false)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBooltrueequalsBooltrue() throws {
        let predicate = QPredGen.keys.myBool.eq(true)
        var instance = QPredGen(name: "test")
        instance.myBool = true

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testBooltrueequalsBoolfalse() throws {
        let predicate = QPredGen.keys.myBool.eq(true)
        var instance = QPredGen(name: "test")
        instance.myBool = false

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBooltrueequalsBool() throws {
        let predicate = QPredGen.keys.myBool.eq(true)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBoolfalseequalsBooltrue() throws {
        let predicate = QPredGen.keys.myBool.eq(false)
        var instance = QPredGen(name: "test")
        instance.myBool = true

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testBoolfalseequalsBoolfalse() throws {
        let predicate = QPredGen.keys.myBool.eq(false)
        var instance = QPredGen(name: "test")
        instance.myBool = false

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testBoolfalseequalsBool() throws {
        let predicate = QPredGen.keys.myBool.eq(false)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
