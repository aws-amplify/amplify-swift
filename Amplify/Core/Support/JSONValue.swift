//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A utility type that allows us to represent an arbitrary JSON structure
public enum JSONValue {

    /// <#Description#>
    case array([JSONValue])

    /// <#Description#>
    case boolean(Bool)

    /// <#Description#>
    case number(Double)

    /// <#Description#>
    case object([String: JSONValue])

    /// <#Description#>
    case string(String)

    /// <#Description#>
    case null
}

extension JSONValue: Codable {

    /// <#Description#>
    /// - Parameter decoder: <#decoder description#>
    /// - Throws: <#description#>
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
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

    /// <#Description#>
    /// - Parameter encoder: <#encoder description#>
    /// - Throws: <#description#>
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

extension JSONValue: Equatable { }

extension JSONValue: ExpressibleByArrayLiteral {

    /// <#Description#>
    /// - Parameter elements: <#elements description#>
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {

    /// <#Description#>
    /// - Parameter value: <#value description#>
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {

    /// <#Description#>
    /// - Parameter elements: <#elements description#>
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        let dictionary = elements.reduce([String: JSONValue]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .object(dictionary)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {

    /// <#Description#>
    /// - Parameter value: <#value description#>
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {

    /// <#Description#>
    /// - Parameter value: <#value description#>
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}

extension JSONValue: ExpressibleByNilLiteral {

    /// <#Description#>
    /// - Parameter nilLiteral: <#nilLiteral description#>
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSONValue: ExpressibleByStringLiteral {

    /// <#Description#>
    /// - Parameter value: <#value description#>
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
