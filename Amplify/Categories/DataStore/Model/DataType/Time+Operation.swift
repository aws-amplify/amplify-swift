//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct TimeUnit: DateScalarUnit {

    public let component: Calendar.Component
    public let value: Int

    func dateTime(from dateTime: DateTime) -> DateTime {
        return dateTime.add(value: value, to: component)
    }

    func dateTime(to dateTime: DateTime) -> DateTime {
        return dateTime.add(value: -value, to: component)
    }

    func time(from time: Time) -> Time {
        return time.add(value: value, to: component)
    }

    func time(to time: Time) -> Time {
        return time.add(value: -value, to: component)
    }

}

public protocol TimeUnitOperable {

    static func + (left: Self, right: TimeUnit) -> Self

    static func - (left: Self, right: TimeUnit) -> Self

}

extension DateScalar where Self: TimeUnitOperable {

    public static func + (left: Self, right: TimeUnit) -> Self {
        return left.add(value: right.value, to: right.component)
    }

    public static func - (left: Self, right: TimeUnit) -> Self {
        return left.add(value: -right.value, to: right.component)
    }

}

extension Int {

    public var hours: TimeUnit {
        TimeUnit(component: .hour, value: self)
    }

    public var minutes: TimeUnit {
        TimeUnit(component: .minute, value: self)
    }

    public var seconds: TimeUnit {
        TimeUnit(component: .second, value: self)
    }

    public var nanoseconds: TimeUnit {
        TimeUnit(component: .nanosecond, value: self)
    }

}
