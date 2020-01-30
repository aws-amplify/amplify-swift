//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The `DateScalar` protocol defines an [ISO-8601](https://www.iso.org/iso-8601-date-and-time-format.html)
/// formatted Date value. Types that conform to this protocol are responsible for providing
/// the parsing and formatting logic with the correct granularity.
public protocol DateScalar {

    /// Which components are relevant to the Date Scalar implementation.
    static var iso8601DateComponents: Set<Calendar.Component> { get }

    /// The underlying `Date` object. All `DateScalar` implementations must be backed
    /// by a Foundation `Date` instance.
    var date: Date { get }

    /// The ISO-8601 formatted string in the UTC `TimeZone`.
    /// - seealso: iso8601FormattedString(DateScalarFormat, TimeZone) -> String
    var iso8601String: String { get }

    /// Parses an ISO-8601 `String` into a `DateScalar`
    /// - Parameter iso8601String: the string in the ISO8601 format
    /// - Throws: `DataStoreError.decodeError`in case the provided string is not
    /// formatted as expected by the scalar type.
    init(iso8601String: String) throws

    /// A string representation of the underlying date formatted using ISO8601 rules.
    ///
    /// - Parameters:
    ///   - format: the desired format
    ///   - timeZone: the target `TimeZone`
    /// - Returns: the ISO8601 formatted string in the requested format
    func iso8601FormattedString(format: DateScalarFormat, timeZone: TimeZone) -> String

}

extension DateScalar {

    static var iso8601Calendar: Calendar { Calendar(identifier: .iso8601) }

    /// Utility used to created an ISO8601 with a pre-defined timezone `DateFormatter`.
    ///
    /// - Parameters:
    ///   - format: the desired format
    ///   - timeZone: the target `TimeZone`
    static func iso8601DateFormatter(format: DateScalarFormat,
                                     timeZone: TimeZone = .utc) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = iso8601Calendar
        formatter.dateFormat = format.getFormat(for: Self.self)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }

    static func iso8601Date(from iso8601String: String) -> Date? {
        var date: Date?
        for format in DateScalarFormat.allCases {
            let formatter = Self.iso8601DateFormatter(format: format)
            if let convertedDate = formatter.date(from: iso8601String) {
                date = convertedDate
                break
            }
        }
        return date
    }

    public func iso8601FormattedString(format: DateScalarFormat,
                                       timeZone: TimeZone = .utc) -> String {
        let formatter = Self.iso8601DateFormatter(format: format, timeZone: timeZone)
        return formatter.string(from: date)
    }

    /// The ISO8601 representation of the scalar using `.full` as the format and `.utc` as `TimeZone`.
    /// - seealso: iso8601FormattedString(DateScalarFormat, TimeZone)
    public var iso8601String: String {
        iso8601FormattedString(format: .full, timeZone: .utc)
    }
}

extension TimeZone {

    /// Utility UTC ("Coordinated Universal Time") TimeZone instance.
    public static var utc: TimeZone {
        TimeZone(abbreviation: "UTC")!
    }
}
