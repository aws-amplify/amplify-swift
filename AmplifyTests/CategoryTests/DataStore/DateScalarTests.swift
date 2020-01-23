//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

let pst = TimeZone(secondsFromGMT: -28_800)!

class DateScalarTests: XCTestCase {

    // MARK: - DateTime

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testShortDateTimeParsing() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.0000Z")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20T00:00:00.0000")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20T08:00:00.0000")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20T00:00:00.0000-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20T08:00:00.0000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the `utc` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testMediumDateTimeParsing() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.0000Z")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20T00:00:00.0000")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20T08:00:00.0000")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20T00:00:00.0000-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20T08:00:00.0000Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testLongDateTimeParsing() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00.1800")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.1800Z")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20T00:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20T08:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20T00:00:00.1800-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20T08:00:00.1800Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the provided `utc` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullDateTimeParsingOnUTC() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00.1800Z")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T08:00:00.1800Z")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20T00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20T00:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20T00:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20T08:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20T00:00:00.1800-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20T08:00:00.1800Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` string
    /// - When:
    ///   - the input format is `yyyy-MM-dd'T'HH:mm:ss.SSSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `DateTime` instance
    ///   - it should use the provided `pst` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullDateTimeParsingOnPST() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00.1800-08:00")
            XCTAssertEqual(datetime.iso8601String, "2020-01-20T16:00:00.1800Z")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20T08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20T16:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20T08:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20T16:00:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20T08:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20T16:00:00.1800")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20T08:00:00.1800-08:00")
            XCTAssertEqual(datetime.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20T16:00:00.1800Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testShortDateParsing() {
        do {
            let date = try Date(iso8601String: "2020-01-20")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-19")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullDateParsingOnUTC() {
        do {
            let date = try Date(iso8601String: "2020-01-20Z")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-19")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-19-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullDateParsingOnPST() {
        do {
            let date = try Date(iso8601String: "2020-01-20-08:00")
            XCTAssertEqual(date.iso8601String, "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: pst), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(as: .short, timeZone: .utc), "2020-01-20")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: pst), "2020-01-20-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .medium, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: pst), "2020-01-20-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .long, timeZone: .utc), "2020-01-20Z")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: pst), "2020-01-20-08:00")
            XCTAssertEqual(date.iso8601FormattedString(as: .full, timeZone: .utc), "2020-01-20Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testShortTimeParsing() {
        do {
            let time = try Time(iso8601String: "08:00")
            XCTAssertEqual(time.iso8601String, "08:00:00.0000Z")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: pst), "00:00:00.0000")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: .utc), "08:00:00.0000")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: pst), "00:00:00.0000-08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: .utc), "08:00:00.0000Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testMediumTimeParsing() {
        do {
            let time = try Time(iso8601String: "08:00:00")
            XCTAssertEqual(time.iso8601String, "08:00:00.0000Z")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: pst), "00:00:00.0000")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: .utc), "08:00:00.0000")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: pst), "00:00:00.0000-08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: .utc), "08:00:00.0000Z")
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
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testLongTimeParsing() {
        do {
            let time = try Time(iso8601String: "08:00:00.1800")
            XCTAssertEqual(time.iso8601String, "08:00:00.1800Z")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: pst), "00:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: .utc), "08:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: pst), "00:00:00.1800-08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: .utc), "08:00:00.1800Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss.SSSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the provided `utc` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullTimeParsingOnUTC() {
        do {
            let time = try Time(iso8601String: "08:00:00.1800Z")
            XCTAssertEqual(time.iso8601String, "08:00:00.1800Z")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: pst), "00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: .utc), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: pst), "00:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: .utc), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: pst), "00:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: .utc), "08:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: pst), "00:00:00.1800-08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: .utc), "08:00:00.1800Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` string
    /// - When:
    ///   - the input format is `HH:mm:ss.SSSSZZZZZ`
    /// - Then:
    ///   - it should be parsed correctly in a `Time` instance
    ///   - it should use the provided `pst` TimeZone
    ///   - it should output the correctly formatted string for each `DateScalarFormat`
    func testFullTimeParsingOnPST() {
        do {
            let time = try Time(iso8601String: "08:00:00.1800-08:00")
            XCTAssertEqual(time.iso8601String, "16:00:00.1800Z")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: pst), "08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .short, timeZone: .utc), "16:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: pst), "08:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .medium, timeZone: .utc), "16:00:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: pst), "08:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .long, timeZone: .utc), "16:00:00.1800")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: pst), "08:00:00.1800-08:00")
            XCTAssertEqual(time.iso8601FormattedString(as: .full, timeZone: .utc), "16:00:00.1800Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
