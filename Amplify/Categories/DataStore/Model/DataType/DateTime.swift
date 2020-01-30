//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `DateTime` is an immutable `DateScalar` object that represents a date with a time,
/// often viewed as `yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ`.
///
/// `DateTime` can be represented to nanosecond precision and it also holds a reference
/// to a TimeZone. As all Date scalars, `DateTime` relies on the ISO8601 calendar.
public struct DateTime: DateScalar, Comparable {

    public static var iso8601DateComponents: Set<Calendar.Component> {
        [.year, .month, .day, .hour, .minute, .second, .nanosecond, .timeZone]
    }

    public static var now: DateTime {
        DateTime(Date())
    }

    public let date: Date

    public var time: Time {
        Time(date)
    }

    public init(_ date: Date) {
        let calendar = DateTime.iso8601Calendar
        let components = calendar.dateComponents(DateTime.iso8601DateComponents, from: date)
        self.date = components.date ?? date
    }

    public init(iso8601String: String) throws {
        guard let date = DateTime.iso8601Date(from: iso8601String) else {
            throw DataStoreError.invalidDateFormat(iso8601String)
        }
        self.date = date
    }

}

// MARK: - Decodable

extension DateTime: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(iso8601String: value)
    }

}

// MARK: - Encodable

extension DateTime: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }
}
