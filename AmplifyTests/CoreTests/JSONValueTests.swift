//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class JSONValueTests: XCTestCase {

    func testDecode() throws {
        let decoder = JSONDecoder()
        let sourceString = #"{"stringValue": "a string", "numberValue": 123.45, "booleanValue": true}"#
        let sourceData = Data(sourceString.utf8)
        let decodedObject = try decoder.decode(JSONValue.self, from: sourceData)

        let expectedObject: JSONValue = [
            "booleanValue": true,
            "numberValue": 123.45,
            "stringValue": "a string"
        ]

        XCTAssertEqual(decodedObject, expectedObject)
    }

    // This test relies on `sortedKeys` to make string comparison easier
    @available(iOS 11.0, *)
    func testEncode() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let sourceObject: JSONValue = [
            "booleanValue": true,
            "numberValue": 1.2,
            "stringValue": "foo",
            "arrayValue": [1, 2, "three"],
            "objectValue": [
                "bool2": false
            ],
            "nullValue": nil
        ]

        let encodedData = try encoder.encode(sourceObject)
        let encodedString = String(data: encodedData, encoding: .utf8)!
        XCTAssertEqual(
            encodedString,
            #"{"# +
                #""arrayValue":[1,2,"three"],"# +
                #""booleanValue":true,"# +
                #""nullValue":null,"# +
                #""numberValue":1.2,"# +
                #""objectValue":{"bool2":false},"# +
                #""stringValue":"foo""# +
            #"}"#
        )
    }

    func testExpressibleByArrayLiteral() {
        XCTAssertNotNil(["foo", true, 1.0, nil] as JSONValue)
    }

    func testExpressibleByBooleanLiteral() {
        XCTAssertNotNil(true as JSONValue)
    }

    func testExpressibleByDictionaryLiteral() {
        XCTAssertNotNil(["foo": true] as JSONValue)
    }

    func testExpressibleByFloatLiteral() {
        XCTAssertNotNil(1.0 as JSONValue)
    }

    func testExpressibleByIntegerLiteral() {
        XCTAssertNotNil(1 as JSONValue)
    }

    func testExpressibleByNilLiteral() {
        XCTAssertNotNil(nil as JSONValue)
    }

    func testExpressibleByStringLiteral() {
        XCTAssertNotNil("foo" as JSONValue)
    }

    func testEquatable() {
        let enumValue = JSONValue.object(["foo": "bar"])
        let literalValue: JSONValue = ["foo": "bar"]
        XCTAssertEqual(enumValue, literalValue)
    }

    func testDynamicMemberLookup() {
        let json = JSONValue.object(["foo": .object(["bar": 2])])
        XCTAssertEqual(json.foo?.bar?.intValue, 2)
    }

    func testIntValue() {
        let offset = 100000
        let badInt = JSONValue.number(Double(Int.max))
        XCTAssertNil(badInt.intValue)
        let badInt2 = JSONValue.number(Double(Int.min) - Double(offset))
        XCTAssertNil(badInt2.intValue)
        let goodInt = JSONValue.number(Double(100))
        XCTAssertEqual(goodInt.intValue, 100)
    }

    func testDoubleValue() {
        let double = 1000.0
        XCTAssertEqual(JSONValue.number(double).doubleValue, double)
    }

    func testStringValue() {
        let str = UUID().uuidString
        XCTAssertEqual(JSONValue.string(str).stringValue, str)
    }

    func testBooleanValue() {
        let bool = false
        XCTAssertEqual(JSONValue.boolean(bool).booleanValue, bool)
    }

    func testObjectValue() {
        let obj: [String: JSONValue] = [
            "a": "a",
            "b": 0,
            "c": false
        ]

        XCTAssertEqual(JSONValue.object(obj).asObject, obj)
    }

    func testArrayValue() {
        let arr: [JSONValue] = ["a", 0, false]
        XCTAssertEqual(JSONValue.array(arr).asArray, arr)
    }

}
