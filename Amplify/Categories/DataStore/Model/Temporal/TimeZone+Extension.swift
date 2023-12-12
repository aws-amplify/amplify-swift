//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension TimeZone {

    @usableFromInline
    internal init?(iso8601DateString: String) {
        switch ISO8601TimeZonePart.from(iso8601DateString: iso8601DateString) {
        case .some(.utc):
            self.init(abbreviation: "UTC")
        case let .some(.hh(hours: hours)):
            self.init(secondsFromGMT: hours * 60 * 60)
        case let .some(.hhmm(hours: hours, minutes: minutes)),
             let .some(.HHMM(hours: hours, minuts: minutes)):
            self.init(secondsFromGMT: hours * 60 * 60 +
                      (hours > 0 ? 1 : -1) * minutes * 60)
        case let .some(.HHMMSS(hours: hours, minutes: minutes, seconds: seconds)):
            self.init(secondsFromGMT: hours * 60 * 60 +
                      (hours > 0 ? 1 : -1) * minutes * 60 +
                      (hours > 0 ? 1 : -1) * seconds)
        case .none:
            return nil
        }
    }
}


/// ISO8601 Time Zone formats
/// - Note:
///   `±hh:mm:ss` is not a standard of ISO8601 date formate. It's supported by `AWSDateTime` exclusively.
///
/// references:
///   https://en.wikipedia.org/wiki/ISO_8601#Time_zone_designators
///   https://docs.aws.amazon.com/appsync/latest/devguide/scalars.html#graph-ql-aws-appsync-scalars
private enum ISO8601TimeZoneFormat {
    case utc, hh, hhmm, HHMM, HHMMSS

    var format: String {
        switch self {
        case .utc:
            return "Z"
        case .hh:
            return "±hh"
        case .hhmm:
            return "±hhmm"
        case .HHMM:
            return "±hh:mm"
        case .HHMMSS:
            return "±hh:mm:ss"
        }
    }

    var regex: NSRegularExpression? {
        switch self {
        case .utc:
            return try? NSRegularExpression(pattern: "^Z$")
        case .hh:
            return try? NSRegularExpression(pattern: "^[+-]\\d{2}$")
        case .hhmm:
            return try? NSRegularExpression(pattern: "^[+-]\\d{2}\\d{2}$")
        case .HHMM:
            return try? NSRegularExpression(pattern: "^[+-]\\d{2}:\\d{2}$")
        case .HHMMSS:
            return try? NSRegularExpression(pattern: "^[+-]\\d{2}:\\d{2}:\\d{2}$")
        }
    }

    var parts: [NSRange] {
        switch self {
        case .utc:
            return []
        case .hh:
            return [NSRange(location: 0, length: 3)]
        case .hhmm:
            return [
                NSRange(location: 0, length: 3),
                NSRange(location: 3, length: 2)
            ]
        case .HHMM:
            return [
                NSRange(location: 0, length: 3),
                NSRange(location: 4, length: 2)
            ]
        case .HHMMSS:
            return [
                NSRange(location: 0, length: 3),
                NSRange(location: 4, length: 2),
                NSRange(location: 7, length: 2)
            ]
        }
    }
}

private enum ISO8601TimeZonePart {
    case utc
    case hh(hours: Int)
    case hhmm(hours: Int, minutes: Int)
    case HHMM(hours: Int, minuts: Int)
    case HHMMSS(hours: Int, minutes: Int, seconds: Int)

    static func from(iso8601DateString: String) -> ISO8601TimeZonePart? {
        return tryExtract(from: iso8601DateString, with: .utc)
        ?? tryExtract(from: iso8601DateString, with: .hh)
        ?? tryExtract(from: iso8601DateString, with: .hhmm)
        ?? tryExtract(from: iso8601DateString, with: .HHMM)
        ?? tryExtract(from: iso8601DateString, with: .HHMMSS)
        ?? nil
    }
}

private func tryExtract(
    from dateString: String,
    with format: ISO8601TimeZoneFormat
) -> ISO8601TimeZonePart? {
    guard dateString.count > format.format.count else {
        return nil
    }

    let tz = String(dateString.dropFirst(dateString.count - format.format.count))

    guard format.regex.flatMap({
        $0.firstMatch(in: tz, range: NSRange(location: 0, length: tz.count))
    }) != nil else {
        return nil
    }

    let parts = format.parts.compactMap { range in
        Range(range, in: tz).flatMap { Int(tz[$0]) }
    }

    guard parts.count == format.parts.count else {
        return nil
    }

    switch format {
    case .utc: return .utc
    case .hh: return .hh(hours: parts[0])
    case .hhmm: return .hhmm(hours: parts[0], minutes: parts[1])
    case .HHMM: return .HHMM(hours: parts[0], minuts: parts[1])
    case .HHMMSS: return .HHMMSS(hours: parts[0], minutes: parts[1], seconds: parts[2])
    }
}
