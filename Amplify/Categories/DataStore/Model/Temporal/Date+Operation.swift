//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public enum DateUnit {
    /// <#Description#>
    case days(_ value: Int)

    /// <#Description#>
    case weeks(_ value: Int)

    /// <#Description#>
    case months(_ value: Int)

    /// <#Description#>
    case years(_ value: Int)

    /// <#Description#>
    public static let oneDay: DateUnit = .days(1)

    /// <#Description#>
    public static let oneWeek: DateUnit = .weeks(1)

    /// <#Description#>
    public static let oneMonth: DateUnit = .months(1)

    /// <#Description#>
    public static let oneYear: DateUnit = .years(1)

    /// <#Description#>
    public var calendarComponent: Calendar.Component {
        switch self {
        case .days, .weeks:
            return .day
        case .months:
            return .month
        case .years:
            return .year
        }
    }

    /// <#Description#>
    public var value: Int {
        switch self {
        case .days(let value),
             .months(let value),
             .years(let value):
            return value
        case .weeks(let value):
            return value * 7
        }
    }

}

/// <#Description#>
public protocol DateUnitOperable {

    static func + (left: Self, right: DateUnit) -> Self

    static func - (left: Self, right: DateUnit) -> Self

}

extension TemporalSpec where Self: DateUnitOperable {

    /// <#Description#>
    /// - Parameters:
    ///   - left: <#left description#>
    ///   - right: <#right description#>
    /// - Returns: <#description#>
    public static func + (left: Self, right: DateUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - left: <#left description#>
    ///   - right: <#right description#>
    /// - Returns: <#description#>
    public static func - (left: Self, right: DateUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }

}
