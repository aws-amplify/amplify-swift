//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {

    /// `DateTime` is an immutable `TemporalSpec` object that represents a date with a time,
    /// often viewed as `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`.
    ///
    /// `DateTime` can be represented to nanosecond precision and it also holds a reference
    /// to a TimeZone. As all Date scalars, `DateTime` relies on the ISO-8601 calendar.
    public struct DateTime: TemporalSpec, DateUnitOperable, TimeUnitOperable {

        /// <#Description#>
        public static var iso8601DateComponents: Set<Calendar.Component> {
            [.year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone]
        }

        /// <#Description#>
        /// - Returns: <#description#>
        public static func now() -> DateTime {
            return DateTime(Foundation.Date())
        }

        /// <#Description#>
        public let foundationDate: Foundation.Date

        /// <#Description#>
        public var time: Time {
            Time(foundationDate)
        }

        /// <#Description#>
        /// - Parameter date: <#date description#>
        public init(_ date: Foundation.Date) {
            let calendar = DateTime.iso8601Calendar
            let components = calendar.dateComponents(DateTime.iso8601DateComponents, from: date)
            self.foundationDate = components.date ?? date
        }

        /// <#Description#>
        /// - Parameter iso8601String: <#iso8601String description#>
        /// - Throws: <#description#>
        public init(iso8601String: String) throws {
            guard let date = DateTime.iso8601Date(from: iso8601String) else {
                throw DataStoreError.invalidDateFormat(iso8601String)
            }
            self.foundationDate = date
        }

    }

}
