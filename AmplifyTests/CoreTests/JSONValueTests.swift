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
}
