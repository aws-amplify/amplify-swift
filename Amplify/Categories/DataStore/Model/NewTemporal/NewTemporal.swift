//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Temporal` is namespace to all temporal types. It should
/// not be directly instantiated.
///
/// - seealso: Temporal.Date
/// - seealso: Temporal.DateTime
/// - seealso: Temporal.Time
/// - seealso: Temporal.TimeStamp
public enum NewTemporal {
    
    // We apply mutual exlcusion to reads and writes
    // of the formatter cache dict.
    //
    // DateFormatter itself is thread safe.
    private static var formatterCache: [String: DateFormatter] = [:]
    
    @usableFromInline
    internal static let iso8601Calendar: Calendar = {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .utc
        return calendar
    }()
    
    private static var lock = os_unfair_lock_s()
    
    internal static func formatter(
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
    
    public static func date(
        from string: String,
        with formats: [String],
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
