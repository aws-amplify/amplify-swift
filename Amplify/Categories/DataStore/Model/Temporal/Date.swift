//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Temporal {

    /// An extension that makes the `Date` struct conform with the `TemporalSpec` protocol.
    /// When used in persistence operations, the granularity of the different date representations
    /// is set by using different scalar types: `Date`, `DateTime` and `Time`.
    ///
    /// In those scenarios, the standard `Date` is formatted to ISO-8601 without the time.
    /// When the full date information is required, use `DateTime` instead.
    public struct Date: TemporalSpec, DateUnitOperable {

        public static func now() -> Self {
            return Temporal.Date(Foundation.Date())
        }

        public let foundationDate: Foundation.Date

        public init(iso8601String: String) throws {
            guard let date = Temporal.Date.iso8601Date(from: iso8601String) else {
                throw DataStoreError.invalidDateFormat(iso8601String)
            }
            self.foundationDate = date
        }

        public init(_ date: Foundation.Date) {
            // sets the date to a fixed instant so date-only operations are safe
            let calendar = Date.iso8601Calendar
            var components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone],
                from: date
            )
            // reset time to a fixed time
            components.hour = 12
            components.minute = 0
            components.second = 0
            components.nanosecond = 0
            self.foundationDate = calendar.date(from: components) ?? date
        }
    }
}
