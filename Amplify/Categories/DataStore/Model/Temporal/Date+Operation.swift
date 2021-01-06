//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum DateUnit {

    case days(_ value: Int)
    case weeks(_ value: Int)
    case months(_ value: Int)
    case years(_ value: Int)

    public static let oneDay: DateUnit = .days(1)
    public static let oneWeek: DateUnit = .weeks(1)
    public static let oneMonth: DateUnit = .months(1)
    public static let oneYear: DateUnit = .years(1)

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

public protocol DateUnitOperable {

    static func + (left: Self, right: DateUnit) -> Self

    static func - (left: Self, right: DateUnit) -> Self

}

extension TemporalSpec where Self: DateUnitOperable {

    public static func + (left: Self, right: DateUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    public static func - (left: Self, right: DateUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }

}
