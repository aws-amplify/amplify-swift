//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct DateUnit: DateScalarUnit {

    public let component: Calendar.Component
    public let value: Int

    func date(from date: Date) -> Date {
        return date.add(value: value, to: component)
    }

    func date(to date: Date) -> Date {
        return date.add(value: -value, to: component)
    }

    func dateTime(from dateTime: DateTime) -> DateTime {
        return dateTime.add(value: value, to: component)
    }

    func dateTime(to dateTime: DateTime) -> DateTime {
        return dateTime.add(value: -value, to: component)
    }

}

public protocol DateUnitOperable {

    static func + (left: Self, right: DateUnit) -> Self

    static func - (left: Self, right: DateUnit) -> Self

}

extension DateScalar where Self: DateUnitOperable {

    public static func + (left: Self, right: DateUnit) -> Self {
        return left.add(value: right.value, to: right.component)
    }

    public static func - (left: Self, right: DateUnit) -> Self {
        return left.add(value: -right.value, to: right.component)
    }

}

extension Int {

    public var days: DateUnit {
        DateUnit(component: .day, value: self)
    }

    public var weeks: DateUnit {
        DateUnit(component: .day, value: self * 7)
    }

    public var months: DateUnit {
        DateUnit(component: .month, value: self)
    }

    public var years: DateUnit {
        DateUnit(component: .year, value: self)
    }

}
