//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {
    /// `Temporal.DateTime` represents a `DateTime` with specific allowable formats.
    ///
    ///  * `.short` => `yyyy-MM-dd'T'HH:mm`
    ///  * `.medium` => `yyyy-MM-dd'T'HH:mm:ss`
    ///  * `.long` => `yyyy-MM-dd'T'HH:mm:ssZZZZZ`
    ///  * `.full` => `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`
    public struct DateTime: TemporalSpec {
        // Inherits documentation from `TemporalSpec`
        public let foundationDate: Foundation.Date

        // Inherits documentation from `TemporalSpec`
        public static func now() -> Self {
            Temporal.DateTime(Foundation.Date())
        }

        /// `Temporal.Time` of this `Temporal.DateTime`.
        public var time: Time {
            Time(foundationDate)
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
            let calendar = Temporal.iso8601Calendar
            let components = calendar.dateComponents(
                DateTime.iso8601DateComponents,
                from: date
            )

            foundationDate = calendar
                .date(from: components) ?? date
        }

        /// `Calendar.Component`s used in `init(_ date:)`
        static let iso8601DateComponents: Set<Calendar.Component> =
        [
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second,
            .nanosecond,
            .timeZone
        ]
    }
}

// Allow date unit and time unit operations on `Temporal.DateTime`
extension Temporal.DateTime: DateUnitOperable, TimeUnitOperable {}

// Allow `Temporal.DateTime` to be typed erased
extension Temporal.DateTime: AnyTemporalSpec {}
