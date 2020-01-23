//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Time: DateScalar {

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
