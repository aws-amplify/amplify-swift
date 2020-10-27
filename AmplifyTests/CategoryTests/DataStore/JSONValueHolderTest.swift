//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class JSONValueHolderTest: XCTestCase {

    var jsonValueHodler = DynamicModel(values: ["id": 123,
                                                "name": nil,
                                                "comment": "here is a comment"])

    func testJsonDoubleValue() {
        guard let id = jsonValueHodler.jsonValue(for: "id") as? Double else {
            XCTFail("Should cast to Double")
            return
        }
        XCTAssertEqual(id, 123, "Returned value should match")
    }

    func testJsonStringValue() {
        guard let comment = jsonValueHodler.jsonValue(for: "comment") as? String else {
            XCTFail("Should cast to String")
            return
        }
        XCTAssertEqual(comment, "here is a comment", "Returned value should match")
    }

    func testNilJsonValue() {
        let name = jsonValueHodler.jsonValue(for: "name")
        guard case .some(let value) = name else {
            XCTFail("Should cast to an Optional value")
            return
        }
        XCTAssertNil(value, "Returned value should be nil")
    }
}

struct DynamicModel: JSONValueHolder {

    let values: [String: JSONValue]

    public func jsonValue(for key: String) -> Any?? {
        switch values[key] {
        case .some(.array(let deserializedValue)):
            return deserializedValue
        case .some(.boolean(let deserializedValue)):
            return deserializedValue
        case .some(.number(let deserializedValue)):
            return deserializedValue
        case .some(.object(let deserializedValue)):
            return deserializedValue
        case .some(.string(let deserializedValue)):
            return deserializedValue
        case .some(.null):
            return .some(nil)
        case .none:
            return nil
        }
    }

    public func jsonValue(for key: String, modelSchema: ModelSchema) -> Any?? {
        let field = modelSchema.field(withName: key)
        if case .int = field?.type,
           case .some(.number(let deserializedValue)) = values[key] {
            return Int(deserializedValue)
        }
        return jsonValue(for: key)
    }
}
