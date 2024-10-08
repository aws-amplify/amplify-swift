//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

class JSONValueSubscriptTests: XCTestCase {

    func testSubscriptForInt() {
        let intVal: JSONValue = 1
        XCTAssertNil(intVal["foo"])
    }

    func testSubscriptForDouble() {
        let doubleVal: JSONValue = 1.0
        XCTAssertNil(doubleVal["foo"])
    }

    func testSubscriptForBool() {
        let boolVal: JSONValue = true
        XCTAssertNil(boolVal["foo"])
    }

    func testSubscriptForString() {
        let stringVal: JSONValue = "stringVal"
        XCTAssertNil(stringVal["foo"])
    }

    func testSubscriptForNull() {
        let nullVal: JSONValue = nil
        XCTAssertNil(nullVal["foo"])
    }

    func testSubscriptForHomogenousArray() {
        let arrayVal: JSONValue = ["a", "b", "c"]
        XCTAssertEqual(arrayVal[1], "b")
    }

    func testSubscriptForHeterogenousArray() {
        let arrayVal: JSONValue = [0, "b", true]
        XCTAssertEqual(arrayVal[1], "b")
    }

    func testSubscriptForShallowObject() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": 1,
            "c": 2
        ]
        XCTAssertEqual(objectValue["b"], 1)
    }

    func testSubscriptForNestedObject() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b.0": "zero",
                "b.1": 1,
                "b.2": true
            ],
            "c": 2
        ]
        XCTAssertEqual(objectValue["b"]?["b.1"], 1)
    }

    func testMixedSubscripts() {
        let mixedValue: JSONValue = [
            "0": 0,
            "1": [
                "b.0": "zero",
                "b.1": 1,
                "b.2": true
            ],
            "c": 2
        ]
        XCTAssertEqual(mixedValue[1]?["b.1"], 1)
    }
}
