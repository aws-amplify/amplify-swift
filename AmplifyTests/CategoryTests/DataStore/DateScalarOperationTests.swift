//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

class DateScalarOperationTests: XCTestCase {

    // MARK: - Date

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `3.days`) addition operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component added
    func testDateAdditionOperations() {
        do {
            let date = try Date(iso8601String: "2020-01-20")
            XCTAssertEqual((date + 3.days).iso8601String, "2020-01-23Z")
            XCTAssertEqual((date + 2.weeks).iso8601String, "2020-02-03Z")
            XCTAssertEqual((date + 6.months).iso8601String, "2020-07-19Z")
            XCTAssertEqual((date + 4.years).iso8601String, "2024-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `3.days`) subtraction operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component subtracted
    func testDateSubtractionOperations() {
        do {
            let date = try Date(iso8601String: "2020-01-20")
            XCTAssertEqual((date - 3.days).iso8601String, "2020-01-17Z")
            XCTAssertEqual((date - 2.weeks).iso8601String, "2020-01-06Z")
            XCTAssertEqual((date - 6.months).iso8601String, "2019-07-19Z")
            XCTAssertEqual((date - 4.years).iso8601String, "2016-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - DateTime

    /// - Given: a `DateTime` instance with a date/time value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `3.days`) addition operation
    ///   - used on a `TimeUnit` (e.g. `20.minutes`) addition operation
    /// - Then:
    ///   - it should return a new `DateTime` with the correct component added
    func testDateTimeAdditionOperations() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00")
            XCTAssertEqual((datetime + 3.days).iso8601String, "2020-01-23T08:00:00.000Z")
            XCTAssertEqual((datetime + 2.weeks).iso8601String, "2020-02-03T08:00:00.000Z")
            XCTAssertEqual((datetime + 6.months).iso8601String, "2020-07-20T07:00:00.000Z")
            XCTAssertEqual((datetime + 4.years).iso8601String, "2024-01-20T08:00:00.000Z")
            XCTAssertEqual((datetime + 4.hours).iso8601String, "2020-01-20T12:00:00.000Z")
            XCTAssertEqual((datetime + 20.minutes).iso8601String, "2020-01-20T08:20:00.000Z")
            XCTAssertEqual((datetime + 35.seconds).iso8601String, "2020-01-20T08:00:35.000Z")
            XCTAssertEqual((datetime + 100.nanoseconds).iso8601String, "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` instance with a date/time value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `3.days`) subtraction operation
    ///   - used on a `TimeUnit` (e.g. `20.minutes`) subtraction operation
    /// - Then:
    ///   - it should return a new `DateTime` with the correct component subtracted
    func testDateTimeSubtractionOperations() {
        do {
            let datetime = try DateTime(iso8601String: "2020-01-20T08:00:00")
            XCTAssertEqual((datetime - 3.days).iso8601String, "2020-01-17T08:00:00.000Z")
            XCTAssertEqual((datetime - 2.weeks).iso8601String, "2020-01-06T08:00:00.000Z")
            XCTAssertEqual((datetime - 6.months).iso8601String, "2019-07-20T07:00:00.000Z")
            XCTAssertEqual((datetime - 4.years).iso8601String, "2016-01-20T08:00:00.000Z")
            XCTAssertEqual((datetime - 4.hours).iso8601String, "2020-01-20T04:00:00.000Z")
            XCTAssertEqual((datetime - 20.minutes).iso8601String, "2020-01-20T07:40:00.000Z")
            XCTAssertEqual((datetime - 35.seconds).iso8601String, "2020-01-20T07:59:25.000Z")
            XCTAssertEqual((datetime - 100.nanoseconds).iso8601String, "2020-01-20T08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Time

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `20.minutes`) addition operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component added
    func testTimeAdditionOperations() {
        do {
            let time = try Time(iso8601String: "08:00:00")
            XCTAssertEqual((time + 4.hours).iso8601String, "12:00:00.000Z")
            XCTAssertEqual((time + 20.minutes).iso8601String, "08:20:00.000Z")
            XCTAssertEqual((time + 35.seconds).iso8601String, "08:00:35.000Z")
            XCTAssertEqual((time + 100.nanoseconds).iso8601String, "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `20.minutes`) subtraction operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component subtracted
    func testTimeSubtractionOperations() {
        do {
            let time = try Time(iso8601String: "08:00:00")
            XCTAssertEqual((time - 4.hours).iso8601String, "04:00:00.000Z")
            XCTAssertEqual((time - 20.minutes).iso8601String, "07:40:00.000Z")
            XCTAssertEqual((time - 35.seconds).iso8601String, "07:59:25.000Z")
            XCTAssertEqual((time - 100.nanoseconds).iso8601String, "08:00:00.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Date Reference

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `2.days`) reference `from` operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component added
    func testDateFrom() {
        do {
            let januaryTwenty = try Date(iso8601String: "2020-01-20")
            XCTAssertEqual(2.days.date(from: januaryTwenty).iso8601String, "2020-01-22Z")
            XCTAssertEqual(3.months.date(from: januaryTwenty).iso8601String, "2020-04-19Z")
            XCTAssertEqual(4.years.date(from: januaryTwenty).iso8601String, "2024-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - used on a `DateUnit` (e.g. `2.days`) reference `to` operation
    /// - Then:
    ///   - it should return a new `Date` with the correct component subtracted
    func testDateTo() {
        do {
            let januaryTwenty = try Date(iso8601String: "2020-01-20")
            XCTAssertEqual(2.days.date(to: januaryTwenty).iso8601String, "2020-01-18Z")
            XCTAssertEqual(3.months.date(to: januaryTwenty).iso8601String, "2019-10-19Z")
            XCTAssertEqual(4.years.date(to: januaryTwenty).iso8601String, "2016-01-20Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Time Reference

    /// - Given: a `Time` instance with a date value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `5.minutes`) reference `from` operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component added
    func testTimeFrom() {
        do {
            let eight = try Time(iso8601String: "08:00:00")
            XCTAssertEqual(3.hours.time(from: eight).iso8601String, "11:00:00.000Z")
            XCTAssertEqual(5.minutes.time(from: eight).iso8601String, "08:05:00.000Z")
            XCTAssertEqual(30.seconds.time(from: eight).iso8601String, "08:00:30.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` instance with a date value
    /// - When:
    ///   - used on a `TimeUnit` (e.g. `5.minutes`) reference `to` operation
    /// - Then:
    ///   - it should return a new `Time` with the correct component subtracted
    func testTimeTo() {
        do {
            let eight = try Time(iso8601String: "08:00:00")
            XCTAssertEqual(3.hours.time(to: eight).iso8601String, "05:00:00.000Z")
            XCTAssertEqual(5.minutes.time(to: eight).iso8601String, "07:55:00.000Z")
            XCTAssertEqual(30.seconds.time(to: eight).iso8601String, "07:59:30.000Z")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
