//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public enum TimeUnit {

    /// <#Description#>
    case hours(_ value: Int)

    /// <#Description#>
    case minutes(_ value: Int)

    /// <#Description#>
    case seconds(_ value: Int)

    /// <#Description#>
    case milliseconds(_ value: Int)

    /// <#Description#>
    case nanoseconds(_ value: Int)

    /// <#Description#>
    public static let oneSecond: TimeUnit = .seconds(1)

    /// <#Description#>
    public static let oneMinute: TimeUnit = .minutes(1)

    /// <#Description#>
    public static let oneHour: TimeUnit = .hours(1)

    /// <#Description#>
    public var calendarComponent: Calendar.Component {
        switch self {
        case .hours:
            return .hour
        case .minutes:
            return .minute
        case .seconds:
            return .second
        case .nanoseconds, .milliseconds:
            return .nanosecond
        }
    }

    /// <#Description#>
    public var value: Int {
        switch self {
        case .hours(let value),
             .minutes(let value),
             .seconds(let value),
             .nanoseconds(let value):
            return value
        case .milliseconds(let value):
            return value * 1_000_000
        }
    }

}

/// <#Description#>
public protocol TimeUnitOperable {

    static func + (left: Self, right: TimeUnit) -> Self

    static func - (left: Self, right: TimeUnit) -> Self

}

extension TemporalSpec where Self: TimeUnitOperable {

    /// <#Description#>
    /// - Parameters:
    ///   - left: <#left description#>
    ///   - right: <#right description#>
    /// - Returns: <#description#>
    public static func + (left: Self, right: TimeUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - left: <#left description#>
    ///   - right: <#right description#>
    /// - Returns: <#description#>
    public static func - (left: Self, right: TimeUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }

}
