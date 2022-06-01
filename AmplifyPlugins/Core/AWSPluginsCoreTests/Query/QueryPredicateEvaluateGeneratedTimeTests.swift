//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable line_length
class QueryPredicateEvaluateGeneratedTimeTests: XCTestCase {
    func testTemporalTimeTemporal_Time_nownotEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nownotEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nownotEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nownotEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nownotEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hournotEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hournotEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hournotEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hournotEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hournotEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hournotEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hournotEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hournotEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hournotEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hournotEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hournotEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hournotEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hournotEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hournotEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hournotEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ne(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowequalsTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowequalsTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowequalsTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowequalsTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowequalsTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourequalsTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourequalsTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourequalsTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourequalsTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourequalsTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourequalsTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourequalsTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourequalsTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourequalsTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourequalsTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourequalsTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourequalsTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourequalsTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourequalsTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourequalsTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.eq(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.le(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowlessThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourlessThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourlessThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourlessThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.lt(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterOrEqualTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterOrEqualTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterOrEqualTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.ge(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow)
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_nowgreaterThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue1to_hourgreaterThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue2to_hourgreaterThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterThanTemporalTimeTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterThanTemporalTimeTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalTimeTemporal_Time_now_addvalue3to_hourgreaterThanTemporalTime() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.gt(timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwithTemporal_Time_now() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwithTemporal_Time_now_addvalue1to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwithTemporal_Time_now_addvalue2to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwithTemporal_Time_now_addvalue3to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwithTemporal_Time_now_addvalue4to_hour() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myTime = timeNow.add(value: 4, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalTimeTemporal_Time_now_addvalue1to_hourbetweenTemporalTimeTemporal_Time_now_addvalue3to_hourwith() throws {
        let timeNow = try Temporal.Time.init(iso8601String: "10:16:44")
        let predicate = QPredGen.keys.myTime.between(start: timeNow.add(value: 1, to: .hour), end: timeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
