//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension _Temporal {
    public struct DateTime: _TemporalSpec {
        public let foundationDate: Foundation.Date
        
        public static func now() -> Self {
            _Temporal.DateTime(Foundation.Date())
        }
        
        public var time: Time {
            Time(foundationDate)
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
            let calendar = _Temporal.iso8601Calendar
            let components = calendar.dateComponents(
                DateTime.iso8601DateComponents,
                from: date
            )
            
            foundationDate = calendar
                .date(from: components) ?? date
        }
        
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

extension _Temporal.DateTime {
    public struct Format: TemporalSpecValidFormatRepresentable {
        public let value: String
        
        public static let short = Format(value: "yyyy-MM-dd'T'HH:mm")
        public static let medium = Format(value: "yyyy-MM-dd'T'HH:mm:ss")
        public static let long = Format(value: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        public static let full = Format(value: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")
        public static let unknown = Format(value: "___")

        public static let allFormats: [String] = [
            Self.full.value,
            Self.long.value,
            Self.medium.value,
            Self.short.value
        ]
    }
}

extension _Temporal.DateTime: _DateUnitOperable, _TimeUnitOperable {}
extension _Temporal.DateTime: _AnyTemporalSpec {}
