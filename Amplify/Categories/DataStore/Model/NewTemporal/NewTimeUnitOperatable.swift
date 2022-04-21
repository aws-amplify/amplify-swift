//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol _TimeUnitOperable {

    static func + (left: Self, right: _TimeUnit) -> Self
    static func - (left: Self, right: _TimeUnit) -> Self
}

extension _TemporalSpec where Self: _TimeUnitOperable {

    public static func + (left: Self, right: _TimeUnit) -> Self {
        return left.add(value: right.value, to: right.calendarComponent)
    }

    public static func - (left: Self, right: _TimeUnit) -> Self {
        return left.add(value: -right.value, to: right.calendarComponent)
    }
}
