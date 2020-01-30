//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// An extension that makes the `Date` struct conform with the `DataScalar` protocol.
/// When used in persistence operations, the granularity of the different date representations
/// is set by using different scalar types: `Date`, `DateTime` and `Time`.
///
/// In those scenarios, the standard `Date` is formatted to ISO8601 without the time.
/// When the full date information is required, use `DateTime` instead.
///
extension Date: DateScalar {

    public static var iso8601DateComponents: Set<Calendar.Component> {
        [.year, .month, .day, .timeZone]
    }

    public var date: Date {
        Date(timeInterval: 0, since: self)
    }

    public var dateTime: DateTime {
        DateTime(self)
    }

    public var time: Time {
        Time(self)
    }

    public init(iso8601String: String) throws {
        guard let date = Date.iso8601Date(from: iso8601String) else {
            throw DataStoreError.invalidDateFormat(iso8601String)
        }
        self = date
    }

}
