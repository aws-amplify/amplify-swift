//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

struct DynamicModel: JsonModel {

    public let id: String
    public let values: [String: JSONValue]

    public init(id: String = UUID().uuidString, values: [String: JSONValue]) {
        self.id = id
        self.values = values
    }

    public init(from decoder: Decoder) throws {

        print("DEncode \(decoder)")
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        values = try decoder.singleValueContainer().decode([String: JSONValue].self)
    }

    public func encode(to encoder: Encoder) throws {
        print("Encode")
        var container = encoder.unkeyedContainer()
        try container.encode(values)
    }

    public func internal_value(for key: String) -> Any? {
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
            return nil
        case .none:
            return nil
        }
    }
}

extension DynamicModel {

    public enum CodingKeys: String, ModelKey {
        case id
        case values
    }

    public static let keys = CodingKeys.self
}
