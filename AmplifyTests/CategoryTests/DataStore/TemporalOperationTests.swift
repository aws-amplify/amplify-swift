//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

class TemporalOperationTests: XCTestCase {

    // MARK: - Date

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `.days(3)`) addition operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component added
    func testDateAdditionOperations() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-01-20")
            XCTAssertEqual((date + .days(3)).iso8601String, "2020-01-23Z")
            XCTAssertEqual((date + .weeks(2)).iso8601String, "2020-02-03Z")
            XCTAssertEqual((date + .months(6)).iso8601String, "2020-07-20Z")
            XCTAssertEqual((date + .years(4)).iso8601String, "2024-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `.days(3)`) subtraction operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component subtracted
    func testDateSubtractionOperations() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-01-20")
            XCTAssertEqual((date - .days(3)).iso8601String, "2020-01-17Z")
            XCTAssertEqual((date - .weeks(2)).iso8601String, "2020-01-06Z")
            XCTAssertEqual((date - .months(6)).iso8601String, "2019-07-20Z")
            XCTAssertEqual((date - .years(4)).iso8601String, "2016-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: `2020-02-28` which represents a leap year date
    /// - When:
    ///   - the operation adds one day (`.oneDay`)
    /// - Then:
    ///   - it should return `2020-02-29`
    func testLeapYearOperation() {
        do {
            let date = try Temporal.Date(iso8601String: "2020-02-28")
            XCTAssertEqual((date + .oneDay).iso8601String, "2020-02-29Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - DateTime

    /// - Given: a `DateTime` instance with a date/time value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `.days(3)`) addition operation
    ///   - used on a `TimeUnit` (e.g. `.minutes(20)`) addition operation
    /// - Then:
    ///   - it should return a new `DateTime` with the correct component added
    func testDateTimeAdditionOperations() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00")
            XCTAssertEqual((datetime + .days(3)).iso8601String, "2020-01-23T08:00:00.000Z")
            XCTAssertEqual((datetime + .weeks(2)).iso8601String, "2020-02-03T08:00:00.000Z")
            XCTAssertEqual((datetime + .months(6)).iso8601String, "2020-07-20T08:00:00.000Z")
            XCTAssertEqual((datetime + .years(4)).iso8601String, "2024-01-20T08:00:00.000Z")
            XCTAssertEqual((datetime + .hours(4)).iso8601String, "2020-01-20T12:00:00.000Z")
            XCTAssertEqual((datetime + .minutes(20)).iso8601String, "2020-01-20T08:20:00.000Z")
            XCTAssertEqual((datetime + .seconds(35)).iso8601String, "2020-01-20T08:00:35.000Z")
            XCTAssertEqual((datetime + .nanoseconds(100)).iso8601String, "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` instance with a date/time value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `.days(3)`) subtraction operation
    ///   - used on a `TimeUnit` (e.g. `.minutes(20)`) subtraction operation
    /// - Then:
    ///   - it should return a new `DateTime` with the correct component subtracted
    func testDateTimeSubtractionOperations() {
        do {
            let datetime = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00")
            XCTAssertEqual((datetime - .days(3)).iso8601String, "2020-01-17T08:00:00.000Z")
            XCTAssertEqual((datetime - .weeks(2)).iso8601String, "2020-01-06T08:00:00.000Z")
            XCTAssertEqual((datetime - .months(6)).iso8601String, "2019-07-20T08:00:00.000Z")
            XCTAssertEqual((datetime - .years(4)).iso8601String, "2016-01-20T08:00:00.000Z")
            XCTAssertEqual((datetime - .hours(4)).iso8601String, "2020-01-20T04:00:00.000Z")
            XCTAssertEqual((datetime - .minutes(20)).iso8601String, "2020-01-20T07:40:00.000Z")
            XCTAssertEqual((datetime - .seconds(35)).iso8601String, "2020-01-20T07:59:25.000Z")
            XCTAssertEqual((datetime - .nanoseconds(100)).iso8601String, "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Time

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `.minutes(20)`) addition operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component added
    func testTimeAdditionOperations() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00")
            XCTAssertEqual((time + .hours(4)).iso8601String, "12:00:00.000Z")
            XCTAssertEqual((time + .minutes(20)).iso8601String, "08:20:00.000Z")
            XCTAssertEqual((time + .seconds(35)).iso8601String, "08:00:35.000Z")
            XCTAssertEqual((time + .nanoseconds(100)).iso8601String, "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `.minutes(20)`) subtraction operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component subtracted
    func testTimeSubtractionOperations() {
        do {
            let time = try Temporal.Time(iso8601String: "08:00:00")
            XCTAssertEqual((time - .hours(4)).iso8601String, "04:00:00.000Z")
            XCTAssertEqual((time - .minutes(20)).iso8601String, "07:40:00.000Z")
            XCTAssertEqual((time - .seconds(35)).iso8601String, "07:59:25.000Z")
            XCTAssertEqual((time - .nanoseconds(100)).iso8601String, "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
