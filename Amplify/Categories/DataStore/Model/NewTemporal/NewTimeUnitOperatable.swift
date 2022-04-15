//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol NewTimeUnitOperable {

    static func + (left: Self, right: NewTimeUnit) -> Self
    static func - (left: Self, right: NewTimeUnit) -> Self
}

extension NewTemporalSpec where Self: NewTimeUnitOperable {

    public static func + (left: Self, right: NewTimeUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    public static func - (left: Self, right: NewTimeUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }
}
