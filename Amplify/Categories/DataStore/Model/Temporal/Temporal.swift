//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum NewTemporal {
    
    // We apply mutual exlcusion to reads and writes
    // of the formatter cache dict.
    //
    // DateFormatter itself is thread safe.
    private static var formatterCache: [String: DateFormatter] = [:]
    
    private static let iso8601Calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .utc
        return calendar
    }()
    
    private static var lock = os_unfair_lock_s()
    
    private static func formatter(
        for format: String,
        in timeZone: TimeZone
    ) -> DateFormatter {
        defer { os_unfair_lock_unlock(&lock) }
        
        // lock before read from cache
        os_unfair_lock_lock(&lock)
        if let formatter = formatterCache[format] {
            return formatter
            // defer takes care of unlock
        }
        // unlock if no early return
        os_unfair_lock_unlock(&lock)
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = format
        formatter.calendar = iso8601Calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        
        // lock before write to cache
        os_unfair_lock_lock(&lock)
        formatterCache[format] = formatter
        return formatter
        // defer takes care of unlock
    }
    
    //    public static func date(
    //        from string: String,
    //        with format: String,
    //        in timeZone: TimeZone = .utc
    //    ) throws -> Foundation.Date {
    //        let formatter = formatter(for: format, in: timeZone)
    //        guard let date = formatter.date(from: string) else {
    //            throw DataStoreError
    //                .invalidDateFormat(format)
    //        }
    //        return date
    //    }
    
    public static func date(
        from string: String,
        with formats: String...,
        in timeZone: TimeZone = .utc
    ) throws -> Foundation.Date {
        for format in formats {
            let formatter = formatter(for: format, in: timeZone)
            if let date = formatter.date(from: string) {
                return date
            }
        }
        throw DataStoreError
            .invalidDateFormat(formats.joined(separator: " | "))
    }
    
    public static func string(
        from date: Foundation.Date,
        with format: String,
        in timeZone: TimeZone = .utc
    ) -> String {
        let formatter = formatter(for: format, in: timeZone)
        let string = formatter.string(from: date)
        return string
    }
}

struct NewTemporalSpec {
    public let date: Foundation.Date
    
    static var iso8601Calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .utc
        return calendar
    }
}

extension NewTemporal {
    struct DateFormat<T> {
        let format: () -> [String]
    }
}

extension NewTemporal {
    public struct Date {
        public static func now() -> Self {
            NewTemporal.Date(Foundation.Date())
        }
        
        public let foundationDate: Foundation.Date
        
        public init(
            iso8601String: String,
            format: NewTemporal.Date.Format
        ) throws {
            let date = try NewTemporal.date(
                from: iso8601String,
                with: format.value // figure out unknown
            )
            
            self.init(date)
        }
        
        public init(_ date: Foundation.Date) {
            foundationDate = NewTemporal
                .iso8601Calendar
                .startOfDay(for: date)
        }
        
        public struct Format {
            let value: String
            
            public static let short = Format(value: "yyyy-MM-dd")
            public static let medium = Format(value: "yyyy-MM-ddZZZZZ")
            public static let long = Format(value: "yyyy-MM-ddZZZZZ")
            public static let full = Format(value: "yyyy-MM-ddZZZZZ")
            public static let unknown = Format(value: "___")
        }
    }
    
    public struct Time {
        public static func now() -> Self {
            NewTemporal.Time(Foundation.Date())
        }
        
        public let foundationDate: Foundation.Date
        
        public init(
            iso8601String: String,
            format: NewTemporal.Date.Format
        ) throws {
            let date = try NewTemporal.date(
                from: iso8601String,
                with: format.value // figure out unknown
            )
            
            self.init(date)
        }
        
        public init(_ date: Foundation.Date) {
            let calendar = NewTemporal.iso8601Calendar
            var components = calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second,
                    .nanosecond,
                    .timeZone
                ],
                from: date
            )
            components.year = 2_000
            components.month = 1
            components.day = 1
            
            foundationDate = calendar
                .date(from: components) ?? date
        }
        
        public struct Format {
            let value: String
            
            public static let short = Format(value: "HH:mm")
            public static let medium = Format(value: "HH:mm:ss")
            public static let long = Format(value: "HH:mm:ss.SSS")
            public static let full = Format(value: "HH:mm:ss.SSSZZZZZ")
            public static let unknown = Format(value: "___")
        }
    }
    
    public struct DateTime {
        public static func now() -> Self {
            NewTemporal.DateTime(Foundation.Date())
        }
        
        public let foundationDate: Foundation.Date
        
        static let iso8601DateComponents: Set<Calendar.Component> =
        [
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second,
            .nanosecond,
            .timeZone
        ]
    
        public var time: Time {
            Time(foundationDate)
        }

        public init(
            iso8601String: String,
            format: NewTemporal.Date.Format
        ) throws {
            let date = try NewTemporal.date(
                from: iso8601String,
                with: format.value // figure out unknown
            )
            
            self.init(date)
        }
        
        public init(_ date: Foundation.Date) {
            let calendar = NewTemporal.iso8601Calendar
            var components = calendar.dateComponents(
                DateTime.iso8601DateComponents,
                from: date
            )
            
            foundationDate = calendar
                .date(from: components) ?? date
        }
        
        public struct Format {
            let value: String
            
            public static let short = Format(value: "yyyy-MM-dd'T'HH:mm")
            public static let medium = Format(value: "yyyy-MM-dd'T'HH:mm:ss")
            public static let long = Format(value: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
            public static let full = Format(value: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ")
            public static let unknown = Format(value: "___")
        }
    }
}

public struct Temporal {
    
    /// This struct is used as a namespace to all temporal types. It should
    /// not be directly instantiated.
    ///
    /// - seealso: Temporal.Date
    /// - seealso: Temporal.DateTime
    /// - seealso: Temporal.Time
    /// - seealso: Temporal.TimeStamp
    private init() {}
}

/// The `TemporalSpec` protocol defines an [ISO-8601](https://www.iso.org/iso-8601-date-and-time-format.html)
/// formatted Date value. Types that conform to this protocol are responsible for providing
/// the parsing and formatting logic with the correct granularity.
public protocol TemporalSpec {
    
    /// A static builder that return an instance that represent the current point in time.
    static func now() -> Self
    
    /// The underlying `Date` object. All `TemporalSpec` implementations must be backed
    /// by a Foundation `Date` instance.
    var foundationDate: Foundation.Date { get }
    
    /// The ISO-8601 formatted string in the UTC `TimeZone`.
    /// - seealso: iso8601FormattedString(TemporalFormat, TimeZone) -> String
    var iso8601String: String { get }
    
    /// Parses an ISO-8601 `String` into a `TemporalSpec`.
    ///
    /// - Note: if no timezone is present in the string, `.autoupdatingCurrent` is used.
    ///
    /// - Parameter iso8601String: the string in the ISO8601 format
    /// - Throws: `DataStoreError.decodeError`in case the provided string is not
    /// formatted as expected by the scalar type.
    init(iso8601String: String) throws
    
    /// Constructs a `TemporalSpec` from a `Date` object.
    /// - Parameter date: the `Date` instance that will be used as the reference of the
    /// `TemporalSpec` instance.
    init(_ date: Foundation.Date)
    
    /// A string representation of the underlying date formatted using ISO8601 rules.
    ///
    /// - Parameters:
    ///   - format: the desired format
    ///   - timeZone: the target `TimeZone`
    /// - Returns: the ISO8601 formatted string in the requested format
    func iso8601FormattedString(format: TemporalFormat, timeZone: TimeZone) -> String
    
}

/// Extension to add default implementation to generic members of `TemporalSpec`.
extension TemporalSpec {
    
    static var iso8601Calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .utc
        return calendar
    }
    
    /// Utility used to created an ISO8601 with a pre-defined timezone `DateFormatter`.
    ///
    /// - Parameters:
    ///   - format: the desired format
    ///   - timeZone: the target `TimeZone`
    static func iso8601DateFormatter(format: TemporalFormat,
                                     timeZone: TimeZone = .utc) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = iso8601Calendar
        formatter.dateFormat = format.getFormat(for: Self.self)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }
    
    static func iso8601Date(from iso8601String: String) -> Foundation.Date? {
        var date: Foundation.Date?
        for format in TemporalFormat.sortedCasesForParsing {
            let formatter = Self.iso8601DateFormatter(format: format)
            if let convertedDate = formatter.date(from: iso8601String) {
                date = convertedDate
                break
            }
        }
        return date
    }
    
    public func iso8601FormattedString(format: TemporalFormat,
                                       timeZone: TimeZone = .utc) -> String {
        let formatter = Self.iso8601DateFormatter(format: format, timeZone: timeZone)
        return formatter.string(from: foundationDate)
    }
    
    /// The ISO8601 representation of the scalar using `.full` as the format and `.utc` as `TimeZone`.
    /// - seealso: iso8601FormattedString(TemporalFormat, TimeZone)
    public var iso8601String: String {
        iso8601FormattedString(format: .full)
    }
}

extension TimeZone {
    
    /// Utility UTC ("Coordinated Universal Time") TimeZone instance.
    public static var utc: TimeZone {
        TimeZone(abbreviation: "UTC")!
    }
}
