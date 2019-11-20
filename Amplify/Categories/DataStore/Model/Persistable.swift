//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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
    /// - Note: Maintainers need to keep this utility updated when news types that conform
    /// to `Persistable` are added.
    ///
    /// - Parameters:
    ///   - lhs: a reference to a Persistable object
    ///   - rhs: another reference
    /// - Returns: `true` in case both values are equal or `false` otherwise
    public static func isEqual(_ lhs: Persistable?, _ rhs: Persistable?) -> Bool {
        if lhs == nil && rhs == nil {
            return true
        }
        switch (lhs, rhs) {
        case let (lhs, rhs) as (Bool, Bool):
            return lhs == rhs
        case let (lhs, rhs) as (Date, Date):
            return lhs == rhs
        case let (lhs, rhs) as (Double, Double):
            return lhs == rhs
        case let (lhs, rhs) as (Int, Int):
            return lhs == rhs
        case let (lhs, rhs) as (String, String):
            return lhs == rhs
        default:
            return false
        }
    }
}
