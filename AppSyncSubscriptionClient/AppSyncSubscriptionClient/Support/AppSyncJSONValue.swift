//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A utility type that allows us to represent an arbitrary JSON structure
public enum AppSyncJSONValue {
    case array([AppSyncJSONValue])
    case boolean(Bool)
    case number(Double)
    case object([String: AppSyncJSONValue])
    case string(String)
    case null
}

extension AppSyncJSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([String: AppSyncJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([AppSyncJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

}

extension AppSyncJSONValue: Equatable { }

extension AppSyncJSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AppSyncJSONValue...) {
        self = .array(elements)
    }
}

extension AppSyncJSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension AppSyncJSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AppSyncJSONValue)...) {
        let dictionary = elements.reduce([String: AppSyncJSONValue]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .object(dictionary)
    }
}

extension AppSyncJSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension AppSyncJSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension AppSyncJSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension AppSyncJSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
