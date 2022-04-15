//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct NewTimeUnit {
    public let calendarComponent: Calendar.Component
    public let value: Int
    
    public static func hours(_ value: Int) -> Self {
        .init(calendarComponent: .hour, value: value)
    }
    
    public static func minutes(_ value: Int) -> Self {
        .init(calendarComponent: .minute, value: value)
    }
    
    public static func seconds(_ value: Int) -> Self {
        .init(calendarComponent: .second, value: value)
    }
    
    public static func milliseconds(_ value: Int) -> Self {
        .init(calendarComponent: .nanosecond, value: value * Int(NSEC_PER_MSEC))
    }
    
    public static func nanoseconds(_ value: Int) -> Self {
        .init(calendarComponent: .nanosecond, value: value)
    }
    
    public static let oneSecond: Self = .seconds(1)
    public static let oneMinute: Self = .minutes(1)
    public static let oneHour: Self = .hours(1)
}
