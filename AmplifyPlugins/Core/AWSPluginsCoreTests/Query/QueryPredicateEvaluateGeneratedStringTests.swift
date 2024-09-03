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
class QueryPredicateEvaluateGeneratedStringTests: XCTestCase {
    override func setUp() {
        ModelRegistry.register(modelType: QPredGen.self)
    }

    func testStringanotEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ne("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringanotEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ne("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringanotEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ne("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringanotEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ne("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringanotEqualString() throws {
        let predicate = QPredGen.keys.myString.ne("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbnotEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ne("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbnotEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ne("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbnotEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ne("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbnotEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ne("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbnotEqualString() throws {
        let predicate = QPredGen.keys.myString.ne("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaanotEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ne("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaanotEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ne("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaanotEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ne("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaanotEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ne("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaanotEqualString() throws {
        let predicate = QPredGen.keys.myString.ne("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcnotEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ne("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcnotEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ne("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcnotEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ne("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcnotEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ne("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcnotEqualString() throws {
        let predicate = QPredGen.keys.myString.ne("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaequalsStringa() throws {
        let predicate = QPredGen.keys.myString.eq("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaequalsStringbb() throws {
        let predicate = QPredGen.keys.myString.eq("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaequalsStringaa() throws {
        let predicate = QPredGen.keys.myString.eq("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaequalsStringc() throws {
        let predicate = QPredGen.keys.myString.eq("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaequalsString() throws {
        let predicate = QPredGen.keys.myString.eq("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbequalsStringa() throws {
        let predicate = QPredGen.keys.myString.eq("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbequalsStringbb() throws {
        let predicate = QPredGen.keys.myString.eq("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbequalsStringaa() throws {
        let predicate = QPredGen.keys.myString.eq("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbequalsStringc() throws {
        let predicate = QPredGen.keys.myString.eq("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbequalsString() throws {
        let predicate = QPredGen.keys.myString.eq("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaaequalsStringa() throws {
        let predicate = QPredGen.keys.myString.eq("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaaequalsStringbb() throws {
        let predicate = QPredGen.keys.myString.eq("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaaequalsStringaa() throws {
        let predicate = QPredGen.keys.myString.eq("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaaequalsStringc() throws {
        let predicate = QPredGen.keys.myString.eq("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaaequalsString() throws {
        let predicate = QPredGen.keys.myString.eq("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcequalsStringa() throws {
        let predicate = QPredGen.keys.myString.eq("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcequalsStringbb() throws {
        let predicate = QPredGen.keys.myString.eq("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcequalsStringaa() throws {
        let predicate = QPredGen.keys.myString.eq("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcequalsStringc() throws {
        let predicate = QPredGen.keys.myString.eq("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcequalsString() throws {
        let predicate = QPredGen.keys.myString.eq("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.le("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringalessOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.le("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.le("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.le("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessOrEqualString() throws {
        let predicate = QPredGen.keys.myString.le("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbblessOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.le("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbblessOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.le("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbblessOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.le("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbblessOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.le("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbblessOrEqualString() throws {
        let predicate = QPredGen.keys.myString.le("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.le("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaalessOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.le("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.le("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaalessOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.le("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessOrEqualString() throws {
        let predicate = QPredGen.keys.myString.le("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringclessOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.le("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.le("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.le("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.le("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessOrEqualString() throws {
        let predicate = QPredGen.keys.myString.le("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessThanStringa() throws {
        let predicate = QPredGen.keys.myString.lt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessThanStringbb() throws {
        let predicate = QPredGen.keys.myString.lt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessThanStringaa() throws {
        let predicate = QPredGen.keys.myString.lt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessThanStringc() throws {
        let predicate = QPredGen.keys.myString.lt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringalessThanString() throws {
        let predicate = QPredGen.keys.myString.lt("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbblessThanStringa() throws {
        let predicate = QPredGen.keys.myString.lt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbblessThanStringbb() throws {
        let predicate = QPredGen.keys.myString.lt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbblessThanStringaa() throws {
        let predicate = QPredGen.keys.myString.lt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbblessThanStringc() throws {
        let predicate = QPredGen.keys.myString.lt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbblessThanString() throws {
        let predicate = QPredGen.keys.myString.lt("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessThanStringa() throws {
        let predicate = QPredGen.keys.myString.lt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaalessThanStringbb() throws {
        let predicate = QPredGen.keys.myString.lt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessThanStringaa() throws {
        let predicate = QPredGen.keys.myString.lt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessThanStringc() throws {
        let predicate = QPredGen.keys.myString.lt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaalessThanString() throws {
        let predicate = QPredGen.keys.myString.lt("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringclessThanStringa() throws {
        let predicate = QPredGen.keys.myString.lt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessThanStringbb() throws {
        let predicate = QPredGen.keys.myString.lt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessThanStringaa() throws {
        let predicate = QPredGen.keys.myString.lt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringclessThanStringc() throws {
        let predicate = QPredGen.keys.myString.lt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringclessThanString() throws {
        let predicate = QPredGen.keys.myString.lt("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringagreaterOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ge("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ge("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ge("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ge("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterOrEqualString() throws {
        let predicate = QPredGen.keys.myString.ge("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ge("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ge("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbgreaterOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ge("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ge("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbgreaterOrEqualString() throws {
        let predicate = QPredGen.keys.myString.ge("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaagreaterOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ge("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaagreaterOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ge("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaagreaterOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ge("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaagreaterOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ge("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaagreaterOrEqualString() throws {
        let predicate = QPredGen.keys.myString.ge("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterOrEqualStringa() throws {
        let predicate = QPredGen.keys.myString.ge("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterOrEqualStringbb() throws {
        let predicate = QPredGen.keys.myString.ge("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterOrEqualStringaa() throws {
        let predicate = QPredGen.keys.myString.ge("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterOrEqualStringc() throws {
        let predicate = QPredGen.keys.myString.ge("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcgreaterOrEqualString() throws {
        let predicate = QPredGen.keys.myString.ge("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringagreaterThanStringa() throws {
        let predicate = QPredGen.keys.myString.gt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringagreaterThanStringbb() throws {
        let predicate = QPredGen.keys.myString.gt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterThanStringaa() throws {
        let predicate = QPredGen.keys.myString.gt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterThanStringc() throws {
        let predicate = QPredGen.keys.myString.gt("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringagreaterThanString() throws {
        let predicate = QPredGen.keys.myString.gt("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterThanStringa() throws {
        let predicate = QPredGen.keys.myString.gt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterThanStringbb() throws {
        let predicate = QPredGen.keys.myString.gt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterThanStringaa() throws {
        let predicate = QPredGen.keys.myString.gt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbgreaterThanStringc() throws {
        let predicate = QPredGen.keys.myString.gt("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbgreaterThanString() throws {
        let predicate = QPredGen.keys.myString.gt("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaagreaterThanStringa() throws {
        let predicate = QPredGen.keys.myString.gt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaagreaterThanStringbb() throws {
        let predicate = QPredGen.keys.myString.gt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaagreaterThanStringaa() throws {
        let predicate = QPredGen.keys.myString.gt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaagreaterThanStringc() throws {
        let predicate = QPredGen.keys.myString.gt("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaagreaterThanString() throws {
        let predicate = QPredGen.keys.myString.gt("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterThanStringa() throws {
        let predicate = QPredGen.keys.myString.gt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterThanStringbb() throws {
        let predicate = QPredGen.keys.myString.gt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterThanStringaa() throws {
        let predicate = QPredGen.keys.myString.gt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterThanStringc() throws {
        let predicate = QPredGen.keys.myString.gt("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcgreaterThanString() throws {
        let predicate = QPredGen.keys.myString.gt("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringacontainsStringa() throws {
        let predicate = QPredGen.keys.myString.contains("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringacontainsStringbb() throws {
        let predicate = QPredGen.keys.myString.contains("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringacontainsStringaa() throws {
        let predicate = QPredGen.keys.myString.contains("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringacontainsStringc() throws {
        let predicate = QPredGen.keys.myString.contains("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringacontainsString() throws {
        let predicate = QPredGen.keys.myString.contains("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbcontainsStringa() throws {
        let predicate = QPredGen.keys.myString.contains("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbcontainsStringbb() throws {
        let predicate = QPredGen.keys.myString.contains("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbcontainsStringaa() throws {
        let predicate = QPredGen.keys.myString.contains("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbcontainsStringc() throws {
        let predicate = QPredGen.keys.myString.contains("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbcontainsString() throws {
        let predicate = QPredGen.keys.myString.contains("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaacontainsStringa() throws {
        let predicate = QPredGen.keys.myString.contains("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaacontainsStringbb() throws {
        let predicate = QPredGen.keys.myString.contains("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaacontainsStringaa() throws {
        let predicate = QPredGen.keys.myString.contains("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaacontainsStringc() throws {
        let predicate = QPredGen.keys.myString.contains("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaacontainsString() throws {
        let predicate = QPredGen.keys.myString.contains("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringccontainsStringa() throws {
        let predicate = QPredGen.keys.myString.contains("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringccontainsStringbb() throws {
        let predicate = QPredGen.keys.myString.contains("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringccontainsStringaa() throws {
        let predicate = QPredGen.keys.myString.contains("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringccontainsStringc() throws {
        let predicate = QPredGen.keys.myString.contains("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringccontainsString() throws {
        let predicate = QPredGen.keys.myString.contains("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenStringbbbetweenStringddwitha() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenStringbbbetweenStringddwithbb() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenStringbbbetweenStringddwithc() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenStringbbbetweenStringddwithdd() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        var instance = QPredGen(name: "test")
        instance.myString = "dd"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenStringbbbetweenStringddwithe() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        var instance = QPredGen(name: "test")
        instance.myString = "e"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenStringbbbetweenStringddwith() throws {
        let predicate = QPredGen.keys.myString.between(start: "bb", end: "dd")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringabeginsWithStringa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("a")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringabeginsWithStringbb() throws {
        let predicate = QPredGen.keys.myString.beginsWith("a")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringabeginsWithStringaa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("a")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringabeginsWithStringc() throws {
        let predicate = QPredGen.keys.myString.beginsWith("a")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringabeginsWithString() throws {
        let predicate = QPredGen.keys.myString.beginsWith("a")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbbeginsWithStringa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbbeginsWithStringbb() throws {
        let predicate = QPredGen.keys.myString.beginsWith("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringbbbeginsWithStringaa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbbeginsWithStringc() throws {
        let predicate = QPredGen.keys.myString.beginsWith("bb")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringbbbeginsWithString() throws {
        let predicate = QPredGen.keys.myString.beginsWith("bb")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaabeginsWithStringa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaabeginsWithStringbb() throws {
        let predicate = QPredGen.keys.myString.beginsWith("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaabeginsWithStringaa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringaabeginsWithStringc() throws {
        let predicate = QPredGen.keys.myString.beginsWith("aa")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringaabeginsWithString() throws {
        let predicate = QPredGen.keys.myString.beginsWith("aa")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcbeginsWithStringa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("c")
        var instance = QPredGen(name: "test")
        instance.myString = "a"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcbeginsWithStringbb() throws {
        let predicate = QPredGen.keys.myString.beginsWith("c")
        var instance = QPredGen(name: "test")
        instance.myString = "bb"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcbeginsWithStringaa() throws {
        let predicate = QPredGen.keys.myString.beginsWith("c")
        var instance = QPredGen(name: "test")
        instance.myString = "aa"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testStringcbeginsWithStringc() throws {
        let predicate = QPredGen.keys.myString.beginsWith("c")
        var instance = QPredGen(name: "test")
        instance.myString = "c"

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testStringcbeginsWithString() throws {
        let predicate = QPredGen.keys.myString.beginsWith("c")
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
