//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension _Temporal {
    public struct Time: _TemporalSpec {
        public let foundationDate: Foundation.Date
        
        public static func now() -> Self {
            _Temporal.Time(Foundation.Date())
        }
                
        @inlinable
        @inline(never)
        public init(
            iso8601String: String,
            format: Self.Format = .unknown
        ) throws {
            let date = try SpecBasedDateConverting<Self>()
                .convert(iso8601String, format)
            self.init(date)
        }
        
        public init(_ date: Foundation.Date) {
            // sets the date to a fixed instant so time-only operations are safe
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
            // this is the same behavior of Foundation.Date when parsed from strings
            // without year-month-day information
            components.year = 2_000
            components.month = 1
            components.day = 1
            
            foundationDate = calendar
                .date(from: components) ?? date
        }
    }
}

extension _Temporal.Time {
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String
        
        public static let short = Format(value: "HH:mm")
        public static let medium = Format(value: "HH:mm:ss")
        public static let long = Format(value: "HH:mm:ss.SSS")
        public static let full = Format(value: "HH:mm:ss.SSSZZZZZ")
        public static let unknown = Format(value: "___")
        
        public static let allFormats: [String] = [
            Self.full.value,
            Self.long.value,
            Self.medium.value,
            Self.short.value
        ]
    }
}

extension _Temporal.Time: _TimeUnitOperable {}
extension _Temporal.Time: _AnyTemporalSpec {}
