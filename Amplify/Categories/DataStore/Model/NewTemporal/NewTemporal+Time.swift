//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension _Temporal {
    /// `Temporal.Time` represents a `Time` with specific allowable formats.
    ///
    ///  * `.short` => `HH:mm`
    ///  * `.medium` => `HH:mm:ss`
    ///  * `.long` => `HH:mm:ss.SSS`
    ///  * `.full` => `HH:mm:ss.SSSZZZZZ`
    public struct Time: _TemporalSpec {
        // Inherits documentation from `TemporalSpec`
        public let foundationDate: Foundation.Date

        // Inherits documentation from `TemporalSpec`
        public static func now() -> Self {
            _Temporal.Time(Foundation.Date())
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
            let calendar = _Temporal.iso8601Calendar
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

extension _Temporal.Time {
    /// Allowed `Format`s for `Temporal.Time`
    ///
    ///  * `.short` => `HH:mm`
    ///  * `.medium` => `HH:mm:ss`
    ///  * `.long` => `HH:mm:ss.SSS`
    ///  * `.full` => `HH:mm:ss.SSSZZZZZ`
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String

        /// `HH:mm`
        public static let short = Format(value: "HH:mm")
        /// `HH:mm:ss`
        public static let medium = Format(value: "HH:mm:ss")
        /// `HH:mm:ss.SSS`
        public static let long = Format(value: "HH:mm:ss.SSS")
        /// `HH:mm:ss.SSSZZZZZ`
        public static let full = Format(value: "HH:mm:ss.SSSZZZZZ")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let unknown = Format(value: "___")

        // Inherits documentation from `TemporalSpecValidFormatRepresentable`
        public static let allFormats: [String] = [
            Self.full.value,
            Self.long.value,
            Self.medium.value,
            Self.short.value
        ]
    }
}

// Allow time unit operations on `Temporal.Time`
extension _Temporal.Time: _TimeUnitOperable {}

// Allow `Temporal.Time` to be typed erased
extension _Temporal.Time: _AnyTemporalSpec {}
