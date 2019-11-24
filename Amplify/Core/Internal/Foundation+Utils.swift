//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Allows use of `isEmpty` on optional `Collection`s:
///     let optionalString: String? = getSomeOptionalString()
///     guard optionalString.isEmpty else { return }
///
/// `Collection` provides the `isEmpty` property to declare whether an instance has any members. But it’s also pretty
/// common to expand the definition of “empty” to include nil. Unfortunately, the standard library doesn't include an
/// extension mapping the Collection.isEmpty property, so testing Optional collections means you have to unwrap:
///
///     var optionalString: String?
///     // Do some work
///     if let s = optionalString where s != "" {
///         // s is not empty or nil
///     }
///
/// Or slightly more succinctly, use the nil coalescing operator “??”:
///
///     if !(optionalString ?? "").isEmpty {
///         // optionalString is not empty or nil
///     }
///
/// This extension simply unwraps the `Optional` and returns the value of `isEmpty` for non-nil collections, and returns
/// `true` if the collection is nil.
extension Optional where Wrapped: Collection {
    /// Returns `true` for nil values, or `value.isEmpty` for non-nil values.
    var isEmpty: Bool {
        switch self {
        case .some(let val):
            return val.isEmpty
        case .none:
            return true
        }
    }
}

// TODO: Remove links after taking code ownership
// swiftlint:disable:next line_length
// https://stackoverflow.com/questions/28016578/how-to-create-a-date-time-stamp-and-format-as-iso-8601-rfc-3339-utc-time-zone
extension ISO8601DateFormatter {
    convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
        self.init()
        self.formatOptions = formatOptions
        self.timeZone = timeZone
    }
}

public extension Formatter {
    static let iso8601 = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
    public var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}
public extension String {
    var iso8601: Date? {
        return Formatter.iso8601.date(from: self)
    }
}

// https://useyourloaf.com/blog/swift-codable-with-custom-dates/
// swiftlint:disable:next line_length
// https://stackoverflow.com/questions/46458487/how-to-convert-a-date-string-with-optional-fractional-seconds-using-codable-in-s/46458771#46458771
public extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        // TODO: Is this the correct locale?
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
