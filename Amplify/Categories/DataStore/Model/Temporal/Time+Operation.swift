//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum TimeUnit {

    case hours(_ value: Int)
    case minutes(_ value: Int)
    case seconds(_ value: Int)
    case milliseconds(_ value: Int)
    case nanoseconds(_ value: Int)

    public static let oneSecond: TimeUnit = .seconds(1)
    public static let oneMinute: TimeUnit = .minutes(1)
    public static let oneHour: TimeUnit = .hours(1)

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

public protocol TimeUnitOperable {

    static func + (left: Self, right: TimeUnit) -> Self

    static func - (left: Self, right: TimeUnit) -> Self

}

extension TemporalSpec where Self: TimeUnitOperable {

    public static func + (left: Self, right: TimeUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    public static func - (left: Self, right: TimeUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }

}
