//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

extension TimeZone {
    private static let iso8601TimeZoneHHColonMMRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}:\\d{2}$")
    private static let iso8601TimeZoneHHMMRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}\\d{2}$")
    private static let iso8601TimeZoneHHRegex = try? NSRegularExpression(pattern: "^[+-]\\d{2}$")

    /// https://en.wikipedia.org/wiki/ISO_8601#Time_zone_designators
    @usableFromInline
    internal init?(iso8601DateString: String) {
        func hasMatch(regex: NSRegularExpression?, str: String) -> Bool {
            return regex.flatMap {
                $0.firstMatch(in: str, range: NSRange(location: 0, length: str.count))
            } != nil
        }
        // <time>Z
        func hasSuffixZ() -> Bool {
            return iso8601DateString.hasSuffix("Z")
        }

        // <time>±hh:mm
        func hasSuffixHHColonMM() -> String? {
            if iso8601DateString.count > 6 {
                let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 6))
                if hasMatch(regex: TimeZone.iso8601TimeZoneHHColonMMRegex, str: tz) {
                    return tz
                }
            }
            return nil
        }

        // <time>±hhmm
        func hasSuffixHHMM() -> String? {
            if iso8601DateString.count > 5 {
                let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 5))
                if hasMatch(regex: TimeZone.iso8601TimeZoneHHMMRegex, str: tz) {
                    return tz
                }
            }
            return nil
        }

        // <time>±hh
        func hasSuffixHH() -> String? {
            if iso8601DateString.count > 3 {
                let tz = String(iso8601DateString.dropFirst(iso8601DateString.count - 3))
                if hasMatch(regex: TimeZone.iso8601TimeZoneHHRegex, str: tz) {
                    return tz
                }
            }
            return nil
        }

        if hasSuffixZ() {
            self.init(abbreviation: "UTC")
            return
        }

        if let tz = hasSuffixHHColonMM() {
            guard let hours = Int(tz.dropLast(3)),
                  let mins = Int(tz.dropFirst(4))
            else {
                return nil
            }

            self.init(secondsFromGMT: hours * 60 * 60 + (hours > 0 ? 1 : -1) * mins * 60)
            return
        }

        if let tz = hasSuffixHHMM() {
            guard let hours = Int(tz.dropLast(2)),
                  let mins = Int(tz.dropFirst(3))
            else {
                return nil
            }

            self.init(secondsFromGMT: hours * 60 * 60 + (hours > 0 ? 1 : -1) * mins * 60)
            return
        }

        if let tz = hasSuffixHH() {
            guard let hours = Int(tz) else {
                return nil
            }

            self.init(secondsFromGMT: hours * 60 * 60)
            return
        }

        return nil
    }
}
