//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension DateFormatter {

    // TODO: Are all of the fields needed?
    // https://useyourloaf.com/blog/swift-codable-with-custom-dates/
    // swiftlint:disable line_length
    // https://stackoverflow.com/questions/46458487/how-to-convert-a-date-string-with-optional-fractional-seconds-using-codable-in-s/46458771#46458771
    public static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        // TODO: do we need this? https://www.maddysoft.com/articles/dates.html
        // https://stackoverflow.com/a/28016614
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {

    /// Retrieve the ISO 8601 formatted String, like "2019-11-25T00:35:01.746Z", from the Date instance
    public var iso8601: String {
        return DateFormatter.iso8601Full.string(from: self)
    }
}

extension String {

    /// Retrieve the ISO 8601 Date for valid String values like "2019-11-25T00:35:01.746Z"
    public var iso8601: Date? {
        return DateFormatter.iso8601Full.date(from: self)
    }
}
