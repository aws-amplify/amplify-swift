//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify

class TemporalComparableTests: XCTestCase {

    // MARK: - Date

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - the other `Date` instance has the same value
    /// - Then:
    ///   - it should be equal to other
    ///   - it should be less than other
    ///   - it should be greater than other
    func testDateEquals() {
        do {
            let date1 = try Temporal.Date(iso8601String: "2020-01-20")
            let date2 = try Temporal.Date(iso8601String: "2020-01-20")
            XCTAssertTrue(date1 == date2)
            XCTAssertFalse(date1 != date2)
            XCTAssertTrue(date1 >= date2)
            XCTAssertTrue(date1 <= date2)
            XCTAssertFalse(date1 > date2)
            XCTAssertFalse(date1 < date2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Date` instance with a date value
    /// - When:
    ///   - the other `Date` instance has a different value
    /// - Then:
    ///   - it should not be equal to other
    ///   - it should be less than or equal to other
    ///   - it should be greater than or equal to other
    func testDateNotEquals() {
        do {
            let date1 = try Temporal.Date(iso8601String: "2020-01-20")
            let date2 = try Temporal.Date(iso8601String: "2020-01-21")
            XCTAssertTrue(date1 != date2)
            XCTAssertFalse(date1 > date2)
            XCTAssertFalse(date1 >= date2)
            XCTAssertTrue(date1 < date2)
            XCTAssertTrue(date1 <= date2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - DateTime

    /// - Given: a `DateTime` instance with a time value
    /// - When:
    ///   - the other `DateTime` instance has the same value
    /// - Then:
    ///   - it should be equal to other
    ///   - it should be less than other
    ///   - it should be greater than other
    func testDateTimeEquals() {
        do {
            let datetime1 = try Temporal.DateTime(iso8601String: "2020-01-20T08:00")
            let datetime2 = try Temporal.DateTime(iso8601String: "2020-01-20T08:00")
            XCTAssertTrue(datetime1 == datetime2)
            XCTAssertFalse(datetime1 != datetime2)
            XCTAssertTrue(datetime1 >= datetime2)
            XCTAssertTrue(datetime1 <= datetime2)
            XCTAssertFalse(datetime1 > datetime2)
            XCTAssertFalse(datetime1 < datetime2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` instance with a time value
    /// - When:
    ///   - the other `DateTime` instance has a different value
    /// - Then:
    ///   - it should not be equal to other
    ///   - it should be less than or equal to other
    ///   - it should be greater than or equal to other
    func testDateTimeNotEquals() {
        do {
            let datetime1 = try Temporal.DateTime(iso8601String: "2020-01-20T08:00")
            let datetime2 = try Temporal.DateTime(iso8601String: "2020-01-20T09:00")
            XCTAssertTrue(datetime1 != datetime2)
            XCTAssertFalse(datetime1 == datetime2)
            XCTAssertFalse(datetime1 > datetime2)
            XCTAssertFalse(datetime1 >= datetime2)
            XCTAssertTrue(datetime1 < datetime2)
            XCTAssertTrue(datetime1 <= datetime2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `DateTime` instance within the `UTC` timezone
    /// - When:
    ///   - the other `DateTime` instance is within the `PST` timezone
    /// - Then:
    ///   - it should be equal to other
    ///   - it should be less than or equal to other
    ///   - it should be greater than or equsl to other
    func testDateTimeWithTimezoneEquals() {
        do {
            let datetime1 = try Temporal.DateTime(iso8601String: "2020-01-20T16:00:00.0000Z")
            let datetime2 = try Temporal.DateTime(iso8601String: "2020-01-20T08:00:00.0000-08:00")
            XCTAssertTrue(datetime2 == datetime1)
            XCTAssertFalse(datetime2 != datetime1)
            XCTAssertTrue(datetime1 <= datetime2)
            XCTAssertFalse(datetime2 < datetime1)
            XCTAssertTrue(datetime2 >= datetime1)
            XCTAssertFalse(datetime2 > datetime1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: - Time

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - the other `Time` instance has the same value
    /// - Then:
    ///   - it should be equal to other
    ///   - it should be less than other
    ///   - it should be greater than other
    func testTimeEquals() {
        do {
            let time1 = try Temporal.Time(iso8601String: "08:00")
            let time2 = try Temporal.Time(iso8601String: "08:00")
            XCTAssertTrue(time1 == time2)
            XCTAssertFalse(time1 != time2)
            XCTAssertTrue(time1 >= time2)
            XCTAssertTrue(time1 <= time2)
            XCTAssertFalse(time1 > time2)
            XCTAssertFalse(time1 < time2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` instance with a time value
    /// - When:
    ///   - the other `Time` instance has a different value
    /// - Then:
    ///   - it should not be equal to other
    ///   - it should be less than or equal to other
    ///   - it should be greater than or equal to other
    func testTimeNotEquals() {
        do {
            let time1 = try Temporal.Time(iso8601String: "08:00")
            let time2 = try Temporal.Time(iso8601String: "09:00")
            XCTAssertNotEqual(time1, time2)
            XCTAssertFalse(time1 > time2)
            XCTAssertFalse(time1 >= time2)
            XCTAssertTrue(time1 < time2)
            XCTAssertTrue(time1 <= time2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    /// - Given: a `Time` instance within the `UTC` timezone
    /// - When:
    ///   - the other `Time` instance is within the `PST` timezone
    /// - Then:
    ///   - it should be equal to other
    ///   - it should be less than or equal to other
    ///   - it should be greater than or equsl to other
    func testTimeWithTimezoneEquals() {
        do {
            let time1 = try Temporal.Time(iso8601String: "16:00:00.0000Z")
            let time2 = try Temporal.Time(iso8601String: "08:00:00.0000-08:00")
            XCTAssertTrue(time2 == time1)
            XCTAssertTrue(time1 <= time2)
            XCTAssertTrue(time2 >= time1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // Coding/Decoding

    func testDecodedDateTimeEquality() {
        do {
            let time1 = Temporal.DateTime.now()
            let time2 = try Temporal.DateTime(iso8601String: time1.iso8601String)
            XCTAssertEqual(time1.iso8601String, time2.iso8601String)
            XCTAssertEqual(time1, time2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}
