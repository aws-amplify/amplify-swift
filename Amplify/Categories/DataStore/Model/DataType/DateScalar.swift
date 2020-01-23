//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The `DateScalar` protocol defines an [ISO8601](https://www.iso.org/iso-8601-date-and-time-format.html)
/// formatted Date value. Types that conform to this protocol are responsible for providing
/// the parsing and formatting logic with the correct granularity.
public protocol DateScalar {

    /// Which components are relevant to the Date Scalar implementation
    static var iso8601DateComponents: Set<Calendar.Component> { get }

    /// The underlying `Date` object.
    var date: Date { get }

    /// The ISO8601 formatted string in the UTC `TimeZone`.
    /// - seealso: iso8601FormattedString(DateScalarFormat, TimeZone) -> String
    var iso8601String: String { get }

    /// Parses an ISO8601 `String` into a `DateScalar`
    init(iso8601String: String) throws

    /// A string representation of the underlying date formatted using ISO8601 rules.
    ///
    /// - Parameters:
    ///   - format:
    ///   - timeZone: the target `TimeZone`
    /// - Returns: the ISO8601 formatted string in the requested format
    func iso8601FormattedString(as format: DateScalarFormat, timeZone: TimeZone) -> String

}

extension DateScalar {

    static var iso8601Calendar: Calendar { Calendar(identifier: .iso8601) }

    static func iso8601DateFormatter(format: String,
                                     timeZone: TimeZone = .utc) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = iso8601Calendar
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }

    static func iso8601Date(from iso8601String: String) -> Date? {
        let type = Self.self
        var date: Date?
        for format in DateScalarFormat.allCases {
            let formatter = Self.iso8601DateFormatter(format: format.getFormat(for: type))
            if let convertedDate = formatter.date(from: iso8601String) {
                date = convertedDate
                break
            }
        }
        return date
    }

    public func iso8601FormattedString(as format: DateScalarFormat,
                                       timeZone: TimeZone = .utc) -> String {
        let type = Self.self
        let formatter = Date.iso8601DateFormatter(format: format.getFormat(for: type),
                                                  timeZone: timeZone)
        return formatter.string(from: date)
    }

    public var iso8601String: String {
        iso8601FormattedString(as: .full, timeZone: .utc)
    }
}

extension TimeZone {

    /// Utility UTC ("Coordinated Universal Time") TimeZone instance.
    public static var utc: TimeZone {
        TimeZone(abbreviation: "UTC")!
    }
}
