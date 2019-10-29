//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The `ModelKey` protocol is used to decorate Swift standard's CodingKey enum with
/// query functions and operatiors that are used to build query conditions.
///
/// ```
/// let post = Post.CodingKeys.self
///
/// Amplify.DataStore.query(Post.self, withCriteria: {
///     post.title.contains("[Amplify]")
///     .and(post.content.ne(nil))
/// })
/// ```
///
/// **Using Operators:**
///
/// The operators on a `ModelKey` reference are defined so queries can also be written
/// with Swift operators as well:
///
/// ```
/// let post = Post.CodingKeys.self
///
/// Amplify.DataStore.query(Post.self, withCriteria: {
///     post.title ~= "[Amplify]" &&
///     post.content != nil
/// })
/// ```
///
public protocol ModelKey: CodingKey, CaseIterable {

    // MARK: - Functions

    func beginsWith(_ value: String) -> QueryCondition
    func contains(_ value: String) -> QueryCondition
    func eq(_ value: PersistentValue?) -> QueryCondition
    func ge(_ value: PersistentValue) -> QueryCondition
    func gt(_ value: PersistentValue) -> QueryCondition
    func le(_ value: PersistentValue) -> QueryCondition
    func lt(_ value: PersistentValue) -> QueryCondition
    func ne(_ value: PersistentValue?) -> QueryCondition

    // MARK: - Operators

    static func ~= (key: Self, value: String) -> QueryCondition
    static func == (key: Self, value: PersistentValue?) -> QueryCondition
    static func >= (key: Self, value: PersistentValue) -> QueryCondition
    static func > (key: Self, value: PersistentValue) -> QueryCondition
    static func <= (key: Self, value: PersistentValue) -> QueryCondition
    static func < (key: Self, value: PersistentValue) -> QueryCondition
    static func != (key: Self, value: PersistentValue?) -> QueryCondition
}

extension CodingKey where Self: ModelKey {

    // MARK: - beginsWith
    public func beginsWith(_ value: String) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .beginsWith(value))
    }

    // MARK: - contains

    public func contains(_ value: String) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .contains(value))
    }

    public static func ~= (key: Self, value: String) -> QueryCondition {
        return key.contains(value)
    }

    // MARK: - eq

    public func eq(_ value: PersistentValue?) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .equals(value))
    }

    public static func == (key: Self, value: PersistentValue?) -> QueryCondition {
        return key.eq(value)
    }

    // MARK: - ge

    public func ge(_ value: PersistentValue) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .greaterOrEqual(value))
    }

    public static func >= (key: Self, value: PersistentValue) -> QueryCondition {
        return key.ge(value)
    }

    // MARK: - gt

    public func gt(_ value: PersistentValue) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .greaterThan(value))
    }

    public static func > (key: Self, value: PersistentValue) -> QueryCondition {
        return key.gt(value)
    }

    // MARK: - le

    public func le(_ value: PersistentValue) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .lessOrEqual(value))
    }

    public static func <= (key: Self, value: PersistentValue) -> QueryCondition {
        return key.le(value)
    }

    // MARK: - lt

    public func lt(_ value: PersistentValue) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .lessThan(value))
    }

    public static func < (key: Self, value: PersistentValue) -> QueryCondition {
        return key.lt(value)
    }

    // MARK: - ne

    public func ne(_ value: PersistentValue?) -> QueryCondition {
        return QueryCondition(field: stringValue, predicate: .notEqual(value))
    }

    public static func != (key: Self, value: PersistentValue?) -> QueryCondition {
        return key.ne(value)
    }

}
