//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Creates a new instance of the `QueryField` that can be used to create query predicates.
///
/// ```swift
/// field("id").eq("some-uuid")
/// // or using the operator-based:
/// field("id") == "some-uuid"
/// ```
///
/// - Parameter name: the name of the field
/// - Returns: an instance of the `QueryField`
/// - seealso: `ModelKey` for `CodingKey`-based approach on predicates
public func field(_ name: String) -> QueryField {
    return QueryField(name: name)
}

/// `QueryFieldOperation` provides functions that creates predicates based on a field name.
/// These functions are matchers that get executed at a later point by specific implementations
/// of the `Model` filtering logic (e.g. SQL or GraphQL queries).
///
/// - seealso: `QueryField`
/// - seealso: `ModelKey`
public protocol QueryFieldOperation {
    // MARK: - Functions
    func attributeExists(_ value: Bool) -> QueryPredicateOperation
    func beginsWith(_ value: String) -> QueryPredicateOperation
    func between(start: Persistable, end: Persistable) -> QueryPredicateOperation
    func contains(_ value: String) -> QueryPredicateOperation
    func notContains(_ value: String) -> QueryPredicateOperation
    func eq(_ value: Persistable?) -> QueryPredicateOperation
    func eq(_ value: EnumPersistable) -> QueryPredicateOperation
    func ge(_ value: Persistable) -> QueryPredicateOperation
    func gt(_ value: Persistable) -> QueryPredicateOperation
    func le(_ value: Persistable) -> QueryPredicateOperation
    func lt(_ value: Persistable) -> QueryPredicateOperation
    func ne(_ value: Persistable?) -> QueryPredicateOperation
    func ne(_ value: EnumPersistable) -> QueryPredicateOperation

    // MARK: - Operators

    static func ~= (key: Self, value: String) -> QueryPredicateOperation
    static func == (key: Self, value: Persistable?) -> QueryPredicateOperation
    static func == (key: Self, value: EnumPersistable) -> QueryPredicateOperation
    static func >= (key: Self, value: Persistable) -> QueryPredicateOperation
    static func > (key: Self, value: Persistable) -> QueryPredicateOperation
    static func <= (key: Self, value: Persistable) -> QueryPredicateOperation
    static func < (key: Self, value: Persistable) -> QueryPredicateOperation
    static func != (key: Self, value: Persistable?) -> QueryPredicateOperation
    static func != (key: Self, value: EnumPersistable) -> QueryPredicateOperation
}

public struct QueryField: QueryFieldOperation {

    public let name: String

    // MARK: - attributeExists
    public func attributeExists(_ value: Bool) -> QueryPredicateOperation {
        return .operation(name, .attributeExists(value))
    }

    // MARK: - beginsWith
    public func beginsWith(_ value: String) -> QueryPredicateOperation {
        return .operation(name, .beginsWith(value))
    }

    // MARK: - between
    public func between(start: Persistable, end: Persistable) -> QueryPredicateOperation {
        return .operation(name, .between(start: start, end: end))
    }

    // MARK: - contains

    public func contains(_ value: String) -> QueryPredicateOperation {
        return .operation(name, .contains(value))
    }

    public static func ~= (key: Self, value: String) -> QueryPredicateOperation {
        return key.contains(value)
    }

    // MARK: - not contains
    public func notContains(_ value: String) -> QueryPredicateOperation {
        return .operation(name, .notContains(value))
    }

    // MARK: - eq

    public func eq(_ value: Persistable?) -> QueryPredicateOperation {
        if let value {
            return .operation(name, .equals(value))
        } else {
            return .or([
                .operation(name, .attributeExists(false)),
                .operation(name, .equals(value))
            ])
        }
    }

    public func eq(_ value: EnumPersistable) -> QueryPredicateOperation {
        return .operation(name, .equals(value.rawValue))
    }

    public static func == (key: Self, value: Persistable?) -> QueryPredicateOperation {
        return key.eq(value)
    }

    public static func == (key: Self, value: EnumPersistable) -> QueryPredicateOperation {
        return key.eq(value)
    }

    // MARK: - ge

    public func ge(_ value: Persistable) -> QueryPredicateOperation {
        return .operation(name, .greaterOrEqual(value))
    }

    public static func >= (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.ge(value)
    }

    // MARK: - gt

    public func gt(_ value: Persistable) -> QueryPredicateOperation {
        return .operation(name, .greaterThan(value))
    }

    public static func > (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.gt(value)
    }

    // MARK: - le

    public func le(_ value: Persistable) -> QueryPredicateOperation {
        return .operation(name, .lessOrEqual(value))
    }

    public static func <= (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.le(value)
    }

    // MARK: - lt

    public func lt(_ value: Persistable) -> QueryPredicateOperation {
        return .operation(name, .lessThan(value))
    }

    public static func < (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.lt(value)
    }

    // MARK: - ne

    public func ne(_ value: Persistable?) -> QueryPredicateOperation {
        if let value {
            return .operation(name, .notEqual(value))
        } else {
            return .and([
                .operation(name, .attributeExists(true)),
                .operation(name, .notEqual(value))
            ])
        }

    }

    public func ne(_ value: EnumPersistable) -> QueryPredicateOperation {
        return .operation(name, .notEqual(value.rawValue))
    }

    public static func != (key: Self, value: Persistable?) -> QueryPredicateOperation {
        return key.ne(value)
    }

    public static func != (key: Self, value: EnumPersistable) -> QueryPredicateOperation {
        return key.ne(value)
    }
}
