//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// All persistent models should conform to the Model protocol.
public protocol Model: Codable {

    /// A reference to the `ModelSchema` associated with this model.
    static var schema: ModelSchema { get }

    /// The Model identifier (aka primary key)
    var id: Identifier { get }

}

/// Alias of Model identifier (i.e. primary key)
public typealias Identifier = String

// MARK: - Model subscript

/// Implement dynamic access to properties of a `Model`.
///
/// ```swift
/// let id = model["id"]
/// ```
extension Model {

    public subscript(_ key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        let property = mirror.children.first { $0.label == key }
        return property == nil ? nil : property!.value
    }

    public subscript(_ key: CodingKey) -> Any? {
        return self[key.stringValue]
    }

}

/// Types that conform to the `Persistable` protocol represent values that can be
/// persisted in a database.
///
/// Core Types that conform to this protocol:
/// - `Bool`
/// - `Date`
/// - `Double`
/// - `Int`
/// - `String`
public protocol Persistable {}

extension Bool: Persistable {}
extension Date: Persistable {}
extension Double: Persistable {}
extension Int: Persistable {}
extension String: Persistable {}

struct PersistableHelper {

    /// Polymorphic utility that allows two persistable references to be checked
    /// for equality regardless of their concrete type.
    ///
    /// - Parameters:
    ///   - one: a reference to a Persistable object
    ///   - other: another reference
    /// - Returns: `true` in case both values are equal or `false` otherwise
    public static func isEqual(_ one: Persistable?, to other: Persistable?) -> Bool {
        if one == nil && other == nil {
            return true
        }
        if let one = one as? Bool, let other = other as? Bool {
            return one == other
        }
        if let one = one as? Date, let other = other as? Date {
            return one == other
        }
        if let one = one as? Double, let other = other as? Double {
            return one == other
        }
        if let one = one as? Int, let other = other as? Int {
            return one == other
        }
        if let one = one as? String, let other = other as? String {
            return one == other
        }
        return false
    }
}
