//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {
    /// `Temporal.Time` represents a `Time` with specific allowable formats.
    ///
    ///  * `.short` => `HH:mm`
    ///  * `.medium` => `HH:mm:ss`
    ///  * `.long` => `HH:mm:ss.SSS`
    ///  * `.full` => `HH:mm:ss.SSSZZZZZ`
    public struct Time: TemporalSpec {
        // Inherits documentation from `TemporalSpec`
        public let foundationDate: Foundation.Date

        // Inherits documentation from `TemporalSpec`
        public static func now() -> Self {
            Temporal.Time(Foundation.Date())
        }

        @inlinable
        @inline(never)
        // Inherits documentation from `TemporalSpec`
        public init(
            iso8601String: String,
            format: Self.Format = .unknown
        ) throws {
            let date = try SpecBasedDateConverting<Self>()
                .convert(iso8601String, format)
            self.init(date)
        }

        // Inherits documentation from `TemporalSpec`
        public init(_ date: Foundation.Date) {
            // Sets the date to a fixed instant so time-only operations are safe
            let calendar = Temporal.iso8601Calendar
            var components = calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second,
                    .nanosecond,
                    .timeZone
                ],
                from: date
            )
            // This is the same behavior of Foundation.Date when parsed from strings
            // without year-month-day information
            components.year = 2_000
            components.month = 1
            components.day = 1

            self.foundationDate = calendar
                .date(from: components) ?? date
        }
    }
}

// Allow time unit operations on `Temporal.Time`
extension Temporal.Time: TimeUnitOperable {}

// Allow `Temporal.Time` to be typed erased
extension Temporal.Time: AnyTemporalSpec {}
