//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

class JSONValueKeyPathTests: XCTestCase {

    func testKeyPathForInt() {
        let intVal: JSONValue = 1
        XCTAssertNil(intVal.value(at: "foo"))
    }

    func testKeyPathForDouble() {
        let doubleVal: JSONValue = 1.0
        XCTAssertNil(doubleVal.value(at: "foo"))
    }

    func testKeyPathForBool() {
        let boolVal: JSONValue = true
        XCTAssertNil(boolVal.value(at: "foo"))
    }

    func testKeyPathForString() {
        let stringVal: JSONValue = "stringVal"
        XCTAssertNil(stringVal.value(at: "foo"))
    }

    func testKeyPathForNull() {
        let nullVal: JSONValue = nil
        XCTAssertNil(nullVal.value(at: "foo"))
    }

    func testKeyPathForArray() {
        let arrayVal: JSONValue = ["a", "b", "c"]
        XCTAssertNil(arrayVal.value(at: "1"))
    }

    func testKeyPathForShallowObject() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": 1,
            "c": 2
        ]
        XCTAssertEqual(objectValue.value(at: "b"), 1)
    }

    func testKeyPathForNestedObject() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero",
                "b1": 1,
                "b2": true
            ],
            "c": 2
        ]
        XCTAssertEqual(objectValue.value(at: "b.b1"), 1)
    }

    func testDeeplyNestedObject() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero",
                "b1": [
                    "b10": 0,
                    "b11": true
                ],
                "b2": true
            ],
            "c": 2
        ]
        XCTAssertEqual(objectValue.value(at: "b.b1.b10"), 0)
    }

    func testKeyPathSeparator() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b.0": "zero",
                "b.1": 1,
                "b.2": true
            ],
            "c": 2
        ]
        XCTAssertEqual(objectValue.value(at: "b|b.1", separatedBy: "|"), 1)
    }

    func testInvalidInitialKeyPath() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero",
                "b1": 1,
                "b2": true
            ],
            "c": 2
        ]
        XCTAssertNil(objectValue.value(at: "zzz"))
    }

    func testInvalidIntermediaryKeyPath() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero",
                "b1": [
                    "b10": 0,
                    "b11": true
                ],
                "b2": true
            ],
            "c": 2
        ]
        XCTAssertNil(objectValue.value(at: "b.zzz.b10"))
    }

    func testInvalidTerminalKeyPath() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero",
                "b1": 1,
                "b2": true
            ],
            "c": 2
        ]
        XCTAssertNil(objectValue.value(at: "b.zzz"))
    }

    func testShortKeyPath() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero"
            ],
            "c": 2
        ]
        XCTAssertEqual(objectValue.value(at: "b"), ["b0": "zero"])
    }

    func testTooLongKeyPath() {
        let objectValue: JSONValue = [
            "a": 0,
            "b": [
                "b0": "zero"
            ],
            "c": 2
        ]
        XCTAssertNil(objectValue.value(at: "b.b0.zzz"))
    }

}
