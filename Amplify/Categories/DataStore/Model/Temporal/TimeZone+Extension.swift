//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

extension TimeZone {
    private static let iso8601TimeZoneHHColonMMColonSSRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}:\\d{2}:\\d{2}$")
    private static let iso8601TimeZoneHHColonMMRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}:\\d{2}$")
    private static let iso8601TimeZoneHHMMRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}\\d{2}$")
    private static let iso8601TimeZoneHHRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}$")

    /// ±hh:mm:ss is not a standard of ISO8601 date format, but it's supported by AWSDateTime.
    /// https://docs.aws.amazon.com/appsync/latest/devguide/scalars.html 
    private enum ISO8601TimeZonePart {
        case utc
        case hhmmss(hours: Int, minutes: Int, seconds: Int)
        case hhmm(hours: Int, minutes: Int)
        case hh(hours: Int)

        init?(iso8601DateString: String) {
            func hasMatch(regex: NSRegularExpression?, str: String) -> Bool {
                return regex.flatMap {
                    $0.firstMatch(in: str, range: NSRange(location: 0, length: str.count))
                } != nil
            }

            // <time>±hh:mm:ss
            func suffixHHColonMMColonSS() -> String? {
                if iso8601DateString.count > 9 {
                    let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 9))
                    if hasMatch(regex: TimeZone.iso8601TimeZoneHHColonMMColonSSRegex, str: tz) {
                        return tz
                    }
                }
                return nil
            }

            // <time>±hh:mm
            func suffixHHColonMM() -> String? {
                if iso8601DateString.count > 6 {
                    let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 6))
                    if hasMatch(regex: TimeZone.iso8601TimeZoneHHColonMMRegex, str: tz) {
                        return tz
                    }
                }
                return nil
            }

            // <time>±hhmm
            func suffixHHMM() -> String? {
                if iso8601DateString.count > 5 {
                    let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 5))
                    if hasMatch(regex: TimeZone.iso8601TimeZoneHHMMRegex, str: tz) {
                        return tz
                    }
                }
                return nil
            }

            // <time>±hh
            func suffixHH() -> String? {
                if iso8601DateString.count > 3 {
                    let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 3))
                    if hasMatch(regex: TimeZone.iso8601TimeZoneHHRegex, str: tz) {
                        return tz
                    }
                }
                return nil
            }

            if iso8601DateString.hasPrefix("Z") { // <time>Z
                self = .utc
                return
            }

            if let tz = suffixHHColonMM(),
               let hours = Int(tz.dropLast(3)),
               let minutes = Int(tz.dropFirst(4))
            {
                self = .hhmm(hours: hours, minutes: minutes)
                return
            }

            if let tz = suffixHHMM(),
               let hours = Int(tz.dropLast(2)),
               let minutes = Int(tz.dropFirst(3))
            {
                self = .hhmm(hours: hours, minutes: minutes)
                return
            }

            if let tz = suffixHH(),
               let hours = Int(tz)
            {
                self = .hh(hours: hours)
                return
            }

            if let tz = suffixHHColonMMColonSS(),
               let hours = Int(tz.dropLast(6)),
               let minutes = Int(tz.dropFirst(4).dropLast(3)),
               let seconds = Int(tz.dropFirst(7))
            {
                self = .hhmmss(hours: hours, minutes: minutes, seconds: seconds)
                return
            }

            return nil
        }
    }

    /// https://en.wikipedia.org/wiki/ISO_8601#Time_zone_designators
    @usableFromInline
    internal init?(iso8601DateString: String) {
        switch ISO8601TimeZonePart(iso8601DateString: iso8601DateString) {
        case .some(.utc):
            self.init(abbreviation: "UTC")
        case let .some(.hh(hours: hours)):
            self.init(secondsFromGMT: hours * 60 * 60)
        case let .some(.hhmm(hours: hours, minutes: minutes)):
            self.init(secondsFromGMT: hours * 60 * 60 +
                      (hours > 0 ? 1 : -1) * minutes * 60)
        case let .some(.hhmmss(hours: hours, minutes: minutes, seconds: seconds)):
            self.init(secondsFromGMT: hours * 60 * 60 +
                      (hours > 0 ? 1 : -1) * minutes * 60 +
                      (hours > 0 ? 1 : -1) * seconds)
        case .none:
            return nil
        }
    }
}
