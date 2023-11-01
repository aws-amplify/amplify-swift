//
//  File.swift
//  
//
//  Created by Saultz, Ian on 11/1/23.
//

import Foundation

extension DateFormatter {
    /// A date formatter that converts between dates and the IMF-fixdate, with fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Sun, 02 Jan 2000 20:34:56.000 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithFractionalSeconds = DateFormatter(fixedFormat: "EE, dd MMM yyyy HH:mm:ss.SSS zzz")

    /// A date formatter that converts between dates and the IMF-fixdate, without fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithoutFractionalSeconds = DateFormatter(fixedFormat: "EE, dd MMM yyyy HH:mm:ss zzz")

    /// A date formatter that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.52Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithFractionalSeconds = DateFormatter(
        fixedFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    )

    /// A date formatter that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithoutFractionalSeconds = DateFormatter(
        fixedFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    )

    /// Creates a date formatter with a fixed format.
    /// The formatter's locale will be set to `en_US_POSIX` and the time zone to `UTC`
    ///
    /// For more information, see the _Working With Fixed Format Date Representations_ section in:
    ///  https://developer.apple.com/documentation/foundation/dateformatter
    private convenience init(fixedFormat dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
        self.locale = Locale(identifier: "en_US_POSIX")
        self.timeZone = TimeZone(secondsFromGMT: 0)!
    }
}

struct DateFormatting {
    func date(from string: String, formatter: DateFormatter) -> Date? {
        formatter.date(from: string)
    }

    func string(from date: Date, formatter: DateFormatter) -> String {
        formatter.string(from: date)
    }
}
