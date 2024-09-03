//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The `ModelKey` protocol is used to decorate Swift standard's `CodingKey` enum with
/// query functions and operators that are used to build query conditions.
///
/// ```
/// let post = Post.keys
///
/// Amplify.DataStore.query(Post.self, where: {
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
/// let post = Post.keys
///
/// Amplify.DataStore.query(Post.self, where: {
///     post.title ~= "[Amplify]" &&
///     post.content != nil
/// })
/// ```
public protocol ModelKey: CodingKey, CaseIterable, QueryFieldOperation {}

public extension CodingKey where Self: ModelKey {

    // MARK: - beginsWith
    func beginsWith(_ value: String) -> QueryPredicateOperation {
        return field(stringValue).beginsWith(value)
    }

    // MARK: - between
    func between(start: Persistable, end: Persistable) -> QueryPredicateOperation {
        return field(stringValue).between(start: start, end: end)
    }

    // MARK: - contains

    func contains(_ value: String) -> QueryPredicateOperation {
        return field(stringValue).contains(value)
    }

    static func ~= (key: Self, value: String) -> QueryPredicateOperation {
        return key.contains(value)
    }

    // MARK: - not contains
    func notContains(_ value: String) -> QueryPredicateOperation {
        return field(stringValue).notContains(value)
    }

    // MARK: - eq

    func eq(_ value: Persistable?) -> QueryPredicateOperation {
        return field(stringValue).eq(value)
    }

    func eq(_ value: EnumPersistable) -> QueryPredicateOperation {
        return field(stringValue).eq(value)
    }

    static func == (key: Self, value: Persistable?) -> QueryPredicateOperation {
        return key.eq(value)
    }

    static func == (key: Self, value: EnumPersistable) -> QueryPredicateOperation {
        return key.eq(value)
    }

    // MARK: - ge

    func ge(_ value: Persistable) -> QueryPredicateOperation {
        return field(stringValue).ge(value)
    }

    static func >= (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.ge(value)
    }

    // MARK: - gt

    func gt(_ value: Persistable) -> QueryPredicateOperation {
        return field(stringValue).gt(value)
    }

    static func > (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.gt(value)
    }

    // MARK: - le

    func le(_ value: Persistable) -> QueryPredicateOperation {
        return field(stringValue).le(value)
    }

    static func <= (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.le(value)
    }

    // MARK: - lt

    func lt(_ value: Persistable) -> QueryPredicateOperation {
        return field(stringValue).lt(value)
    }

    static func < (key: Self, value: Persistable) -> QueryPredicateOperation {
        return key.lt(value)
    }

    // MARK: - ne

    func ne(_ value: Persistable?) -> QueryPredicateOperation {
        return field(stringValue).ne(value)
    }

    func ne(_ value: EnumPersistable) -> QueryPredicateOperation {
        return field(stringValue).ne(value)
    }

    static func != (key: Self, value: Persistable?) -> QueryPredicateOperation {
        return key.ne(value)
    }

    static func != (key: Self, value: EnumPersistable) -> QueryPredicateOperation {
        return key.ne(value)
    }

}
