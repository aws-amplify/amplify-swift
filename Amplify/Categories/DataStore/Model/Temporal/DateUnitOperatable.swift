//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Supports addition and subtraction of `Temporal.Date` and `Temporal.DateTime` with `DateUnit`
public protocol DateUnitOperable {
    static func + (left: Self, right: DateUnit) -> Self
    static func - (left: Self, right: DateUnit) -> Self
}

extension TemporalSpec where Self: DateUnitOperable {

    /// Add a `DateUnit` to a `Temporal.Date` or `Temporal.DateTime`
    ///
    ///     let tomorrow = Temporal.Date.now() + .days(1)
    ///
    /// - Parameters:
    ///   - left: `Temporal.Date` or `Temporal.DateTime`
    ///   - right: `DateUnit` to add to `left`
    /// - Returns: A new `Temporal.Date` or `Temporal.DateTime` the `DateUnit` was added to.
    public static func + (left: Self, right: DateUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    /// Subtract a `DateUnit` from a `Temporal.Date` or `Temporal.DateTime`
    ///
    ///     let yesterday = Temporal.Date.now() - .day(1)
    ///
    /// - Parameters:
    ///   - left: `Temporal.Date` or `Temporal.DateTime`
    ///   - right: `DateUnit` to subtract from `left`
    /// - Returns: A new `Temporal.Date` or `Temporal.DateTime` the `DateUnit` was subtracted from.
    public static func - (left: Self, right: DateUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }
}
