//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Custom decoder/encoder to store and retrieve a `QueryOperator`
extension QueryOperator: Codable {

    private enum CodingKeys: String, CodingKey {
        /// QueryOperator type
        case base

        /// Core types that conform to the `Persistable` protocol, including nil case
        case persistableType

        /// Value with type specified by `.persistableType`
        case firstValue

        /// Additional value with type specified by `.persistableType`
        case secondValue
    }

    private enum Base: String, Codable {
        case notEqual
        case equals
        case lessOrEqual
        case lessThan
        case greaterOrEqual
        case greaterThan
        case contains
        case between
        case beginsWith
    }
    private enum PersistableType: String, Codable {
        case bool
        case date
        case double
        case int
        case string
        case null
    }

    // swiftlint:disable cyclomatic_complexity
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let queryOperator = try container.decode(Base.self, forKey: .base)
        let persistableType = try container.decode(PersistableType.self, forKey: .persistableType)
        let value: Persistable?
        switch persistableType {
        case .bool:
            value = try container.decode(Bool.self, forKey: .firstValue)
        case .date:
            value = try container.decode(Date.self, forKey: .firstValue)
        case .double:
            value =  try container.decode(Double.self, forKey: .firstValue)
        case .int:
            value = try container.decode(Int.self, forKey: .firstValue)
        case .string:
            value = try container.decode(String.self, forKey: .firstValue)
        case .null:
            value = nil
        }
        switch queryOperator {
        case .notEqual:
            self = .notEqual(value)
            return
        case .equals:
            self = .equals(value)
            return
        case .lessOrEqual:
            if let value = value {
                self = .lessOrEqual(value)
                return
            }
        case .lessThan:
            if let value = value {
                self = .lessThan(value)
                return
            }
        case .greaterOrEqual:
            if let value = value {
                self = .greaterOrEqual(value)
                return
            }
        case .greaterThan:
            if let value = value {
                self = .greaterThan(value)
                return
            }
        case .contains:
            if let value = value as? String {
                self = .contains(value)
                return
            }
        case .between:
            if let value = value {
                let secondValue = try container.decode(String.self, forKey: .secondValue)
                self = .between(start: value, end: secondValue)
                return
            }
        case .beginsWith:
            if let value = value as? String {
                self = .beginsWith(value)
                return
            }
        }

        throw DataStoreError.decodingError("Error decoding QueryOperator",
                                           "Make sure the conforming types are correct for the QueryOperator used.")
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .notEqual(let value):
            try encodePersistable(encoder, queryOperator: Base.notEqual, firstValue: value)
        case .equals(let value):
            try encodePersistable(encoder, queryOperator: Base.equals, firstValue: value)
        case .lessOrEqual(let value):
            try encodePersistable(encoder, queryOperator: Base.lessOrEqual, firstValue: value)
        case .lessThan(let value):
            try encodePersistable(encoder, queryOperator: Base.lessOrEqual, firstValue: value)
        case .greaterOrEqual(let value):
            try encodePersistable(encoder, queryOperator: Base.greaterOrEqual, firstValue: value)
        case .greaterThan(let value):
            try encodePersistable(encoder, queryOperator: Base.greaterThan, firstValue: value)
        case .contains(let value):
            try encodePersistable(encoder, queryOperator: Base.contains, firstValue: value)
        case .between(let start, let end):
            try encodePersistable(encoder, queryOperator: Base.between, firstValue: start, secondValue: end)
        case .beginsWith(let value):
            try encodePersistable(encoder, queryOperator: Base.beginsWith, firstValue: value)
        }
    }

    private func encodePersistable(_ encoder: Encoder,
                                   queryOperator: Base,
                                   firstValue: Persistable?,
                                   secondValue: Persistable? = nil) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(queryOperator, forKey: .base)

        if let value = firstValue as? Bool {
            try container.encode(PersistableType.bool, forKey: .persistableType)
            try container.encode(value, forKey: .firstValue)
        } else if let value = firstValue as? Date {
            try container.encode(PersistableType.date, forKey: .persistableType)
            try container.encode(value, forKey: .firstValue)
        } else if let value = firstValue as? Double {
            try container.encode(PersistableType.double, forKey: .persistableType)
            try container.encode(value, forKey: .firstValue)
        } else if let value = firstValue as? Int {
            try container.encode(PersistableType.int, forKey: .persistableType)
            try container.encode(value, forKey: .firstValue)
        } else if let value = firstValue as? String {
            try container.encode(PersistableType.string, forKey: .persistableType)
            try container.encode(value, forKey: .firstValue)
        } else {
            try container.encode(PersistableType.null, forKey: .persistableType)
        }

        if let secondValue = secondValue as? Bool {
            try container.encode(secondValue, forKey: .secondValue)
        } else if let secondValue = secondValue as? Date {
            try container.encode(secondValue, forKey: .secondValue)
        } else if let secondValue = secondValue as? Double {
            try container.encode(secondValue, forKey: .secondValue)
        } else if let secondValue = secondValue as? Int {
            try container.encode(secondValue, forKey: .secondValue)
        } else if let secondValue = secondValue as? String {
            try container.encode(secondValue, forKey: .secondValue)
        }
    }
}
