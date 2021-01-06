//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {

    /// `Time` is an immutable `TemporalSpec` object that represents a time, often viewed
    /// as hour-minute-second (`HH:mm:ss`). Time can be represented to nanosecond precision.
    /// For example, the value "13:45:30.123". It can also hold a reference to a TimeZone.
    ///
    /// As all Temporal types, `Time` relies on the ISO8601 calendar and fixed format.
    public struct Time: TemporalSpec, TimeUnitOperable {

        public static var iso8601DateComponents: Set<Calendar.Component> {
            [.hour, .minute, .second, .nanosecond, .timeZone]
        }

        public static func now() -> Time {
            return Time(Foundation.Date())
        }

        public let foundationDate: Foundation.Date

        public init(_ date: Foundation.Date) {
            // sets the date to a fixed instant so time-only operations are safe
            let calendar = Time.iso8601Calendar
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone],
                from: date
            )
            // this is the same behavior of Foundation.Date when parsed from strings
            // without year-month-day information
            components.year = 2_000
            components.month = 1
            components.day = 1
            self.foundationDate = calendar.date(from: components) ?? date
        }

        public init(iso8601String: String) throws {
            guard let date = Time.iso8601Date(from: iso8601String) else {
                throw DataStoreError.invalidDateFormat(iso8601String)
            }
            self.init(date)
        }

    }

}
