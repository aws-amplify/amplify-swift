//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateFormatter {
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static let iso8601DateFormatterWithFractionalSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {
    typealias Millisecond = Int64

    var millisecondsSince1970: Millisecond {
        return Int64(self.timeIntervalSince1970 * 1000)
    }

    var asISO8601String: String {
        return DateFormatter.iso8601Formatter.string(from: self)
    }
}

extension Date.Millisecond {
    var asDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(self / 1000))
            .addingTimeInterval(TimeInterval(Double(self % 1000) / 1000 ))
    }
}
