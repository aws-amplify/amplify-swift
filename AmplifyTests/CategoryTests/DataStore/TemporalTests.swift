//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

let pst = TimeZone(secondsFromGMT: -28_800)!

// swiftlint:disable:next type_body_length
class TemporalTests: XCTestCase {

    // MARK: - DateTime

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm'Z'`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testShortDateTimeParsing() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00Z")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.000Z")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-20T00:00:00-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20T08:00:00Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: pst),
                "2020-01-20T00:00:00.000-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss'Z'`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testMediumDateTimeParsing() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00Z")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.000Z")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-20T00:00:00-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20T08:00:00Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: pst),
                "2020-01-20T00:00:00.000-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss.SSSS`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testLongDateTimeParsing() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00Z")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.000Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .short, timeZone: pst),
                "2020-01-20T00:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .short, timeZone: .utc),
                "2020-01-20T08:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .medium, timeZone: pst),
                "2020-01-20T00:00:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .medium, timeZone: .utc),
                "2020-01-20T08:00:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .long, timeZone: pst),
                "2020-01-20T00:00:00-08:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .long, timeZone: .utc),
                "2020-01-20T08:00:00Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: pst),
                "2020-01-20T00:00:00.000-08:00")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: .utc),
                "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the provided `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullDateTimeParsingOnUTC() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00.180Z")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.180Z")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-20T00:00:00-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20T08:00:00Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: pst),
                "2020-01-20T00:00:00.180-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20T08:00:00.180Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the provided `pst` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullDateTimeParsingOnPST() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00.180-08:00")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T16:00:00.180Z")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20T16:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20T16:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-20T08:00:00-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20T16:00:00Z")
            XCTAssertEqual(
                datetime.iso8601FormattedString(format: .full, timeZone: pst),
                "2020-01-20T08:00:00.180-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20T16:00:00.180Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Date

    /// - Given: a `Date` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd`
    /// - Then:
    ///   - it should be parsed correctly in a `Date` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testShortDateParsing() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-01-20")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-19")
            XCTAssertEqual(date.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .full, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` string
    /// - When:
    ///   - the input format is `yyyy-MM-ddZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Date` instance
    ///   - it should use the provided `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullDateParsingOnUTC() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-01-20Z")
            print("===============")
            print(date)
            print("===============")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .short, timeZone: pst), "2020-01-19")
            XCTAssertEqual(date.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(format: .medium, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .long, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .full, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(format: .full, timeZone: .utc), "2020-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` string
    /// - When:
    ///   - the input format is `yyyy-MM-ddZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Date` instance
    ///   - it should use the provided `pst` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullDateParsingOnPST() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-01-20-08:00")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(format: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(format: .long, timeZone: .utc), "2020-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Time

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testShortTimeParsing() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00")
            XCTAssertEqual(time.iso8601String, "08:00:00.000Z")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: pst), "00:00:00.000")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: .utc), "08:00:00.000")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: pst), "00:00:00.000-08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: .utc), "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testMediumTimeParsing() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00")
            XCTAssertEqual(time.iso8601String, "08:00:00.000Z")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: pst), "00:00:00.000")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: .utc), "08:00:00.000")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: pst), "00:00:00.000-08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: .utc), "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss.SSSS`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testLongTimeParsing() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00.180Z")
            XCTAssertEqual(time.iso8601String, "08:00:00.180Z")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: pst), "00:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: .utc), "08:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: pst), "00:00:00.180-08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: .utc), "08:00:00.180Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss.SSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the provided `utc` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullTimeParsingOnUTC() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00.180Z")
            XCTAssertEqual(time.iso8601String, "08:00:00.180Z")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: pst), "00:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: .utc), "08:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: pst), "00:00:00.180-08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: .utc), "08:00:00.180Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss.SSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the provided `pst` TimeZone
    ///   - it should output the correctly formatted string for each `TemporalFormat`
    func testFullTimeParsingOnPST() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00.180-08:00")
            XCTAssertEqual(time.iso8601String, "16:00:00.180Z")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: pst), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .short, timeZone: .utc), "16:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: pst), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .medium, timeZone: .utc), "16:00:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: pst), "08:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .long, timeZone: .utc), "16:00:00.180")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: pst), "08:00:00.180-08:00")
            XCTAssertEqual(time.iso8601FormattedString(format: .full, timeZone: .utc), "16:00:00.180Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
