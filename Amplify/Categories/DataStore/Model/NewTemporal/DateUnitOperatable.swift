//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Supports addition and subtraction of `Temporal.Date` and `Temporal.DateTime` with `DateUnit`
public protocol _DateUnitOperable {
    static func + (left: Self, right: _DateUnit) -> Self
    static func - (left: Self, right: _DateUnit) -> Self
}

extension _TemporalSpec where Self: _DateUnitOperable {
    
    /// Add a `DateUnit` to a `Temporal.Date` or `Temporal.DateTime`
    /// - Parameters:
    ///   - left: `Temporal.Date` or `Temporal.DateTime`
    ///   - right: `DateUnit` to add to `left`
    /// - Returns: A new `Temporal.Date` or `Temporal.DateTime` the `DateUnit` was added to.
    public static func + (left: Self, right: _DateUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }
    
    /// Subtract a `DateUnit` from a `Temporal.Date` or `Temporal.DateTime`
    /// - Parameters:
    ///   - left: `Temporal.Date` or `Temporal.DateTime`
    ///   - right: `DateUnit` to subtract from `left`
    /// - Returns: A new `Temporal.Date` or `Temporal.DateTime` the `DateUnit` was subtracted from.
    public static func - (left: Self, right: _DateUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }
}
