//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Supports addition and subtraction of `Temporal.Time` and `Temporal.DateTime` with `TimeUnit`
public protocol _TimeUnitOperable {
    static func + (left: Self, right: _TimeUnit) -> Self
    static func - (left: Self, right: _TimeUnit) -> Self
}

extension _TemporalSpec where Self: _TimeUnitOperable {

    /// Add a `TimeUnit` to a `Temporal.Time` or `Temporal.DateTime`
    /// - Parameters:
    ///   - left: `Temporal.Time` or `Temporal.DateTime`
    ///   - right: `TimeUnit` to add to `left`
    /// - Returns: A new `Temporal.Time` or `Temporal.DateTime` the `TimeUnit` was added to.
    public static func + (left: Self, right: _TimeUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    /// Subtract a `TimeUnit` from a `Temporal.Time` or `Temporal.DateTime`
    /// - Parameters:
    ///   - left: `Temporal.Time` or `Temporal.DateTime`
    ///   - right: `TimeUnit` to subtract from `left`
    /// - Returns: A new `Temporal.Time` or `Temporal.DateTime` the `TimeUnit` was subtracted from.
    public static func - (left: Self, right: _TimeUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }
}
