//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Time` is an immutable `DateScalar` object that represents a time, often viewed
/// as hour-minute-second (`HH:mm:ss`). Time can be represented to nanosecond precision.
/// For example, the value "13:45.30.1234". It can also hold a reference to a TimeZone.
///
/// As all Date scalars, `Time` relies on the ISO8601 calendar and fixed format.
public struct Time: DateScalar, Comparable {

    public static var iso8601DateComponents: Set<Calendar.Component> {
        [.hour, .minute, .second, .nanosecond, .timeZone]
    }

    public static var now: Time {
        Time(Date())
    }

    public let date: Date

    public init(_ date: Date) {
        let calendar = Time.iso8601Calendar
        let components = calendar.dateComponents(Time.iso8601DateComponents, from: date)
        print("======================")
        print(components)
        print(components.date)
        print("======================")
        self.date = components.date ?? date
    }

    public init(iso8601String: String) throws {
        guard let date = Time.iso8601Date(from: iso8601String) else {
            throw DataStoreError.invalidDateFormat(iso8601String)
        }
        self.date = date
    }

}

// MARK: - Decodable

extension Time: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(iso8601String: value)
    }

}

// MARK: - Encodable

extension Time: Encodable {

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }
}
