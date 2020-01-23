//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct DateTime: DateScalar {

    public static var iso8601DateComponents: Set<Calendar.Component> {
        [.hour, .minute, .second, .nanosecond, .timeZone]
    }

    public static var now: DateTime {
        DateTime(Date())
    }

    public let date: Date

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
