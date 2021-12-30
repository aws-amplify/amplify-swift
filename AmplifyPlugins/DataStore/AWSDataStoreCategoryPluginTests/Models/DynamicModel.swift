//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct DynamicModel: Model, JSONValueHolder {

    public let id: String
    public var values: [String: JSONValue]

    public init(id: String = UUID().uuidString,
                values: [String: JSONValue]) {
        self.id = id
        var valueWIthId = values
        valueWIthId["id"] = .string(id)
        self.values = valueWIthId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        values = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(values)
    }

    public func jsonValue(for key: String) -> Any?? {
        if key == "id" {
            return id
        }
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

        } else if case .dateTime = field?.type,
                  case .some(.string(let deserializedValue)) = values[key] {

            return try? Temporal.DateTime(iso8601String: deserializedValue)

        } else if case .date = field?.type,
                  case .some(.string(let deserializedValue)) = values[key] {
            return try? Temporal.Date(iso8601String: deserializedValue)

        } else if case .time = field?.type,
                  case .some(.string(let deserializedValue)) = values[key] {
            return try? Temporal.Time(iso8601String: deserializedValue)

        }
        return jsonValue(for: key)
    }
}

extension DynamicModel {

    public enum CodingKeys: String, ModelKey {
        case id
        case values
    }

    public static let keys = CodingKeys.self
}
