//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct DynamicEmbedded: Embeddable, JSONValueHolder {

    public let values: [String: JSONValue]

    public init(map: [String: JSONValue]) {
        self.values = map
    }

    public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)
        if case .object(let jsonValue) = json {
            values = jsonValue
        } else {
            self.values = [:]
        }
    }

    public func encode(to encoder: Encoder) throws {
        var unkeyedContainer = encoder.unkeyedContainer()
        try unkeyedContainer.encode(values)
    }

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
            return nil
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

extension DynamicEmbedded {

    public enum CodingKeys: String, ModelKey {
        case values
    }

    public static let keys = CodingKeys.self

    public static let schema = defineSchema { _ in
        fatalError("Schema for dynamic model should not be called using static method")
    }
}
