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
// swiftlint:disable type_name
// swiftlint:disable line_length
class QueryPredicateEvaluateGeneratedDateTimeTests: XCTestCase {
    func testTemporalDateTimeTemporal_DateTime_nownotEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nownotEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nownotEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nownotEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nownotEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hournotEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hournotEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hournotEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hournotEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hournotEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hournotEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hournotEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ne(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowequalsTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowequalsTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowequalsTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowequalsTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowequalsTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourequalsTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourequalsTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourequalsTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourequalsTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourequalsTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourequalsTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourequalsTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.eq(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.le(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowlessThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourlessThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourlessThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourlessThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.lt(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterOrEqualTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterOrEqualTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.ge(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow)
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_nowgreaterThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow)
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 1, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourgreaterThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 1, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 2, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue2to_hourgreaterThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 2, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterThanTemporalDateTimeTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourgreaterThanTemporalDateTime() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.gt(dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwithTemporal_DateTime_now() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwithTemporal_DateTime_now_addvalue1to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 1, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwithTemporal_DateTime_now_addvalue2to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 2, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwithTemporal_DateTime_now_addvalue3to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 3, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwithTemporal_DateTime_now_addvalue4to_hour() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        var instance = QPredGen(name: "test")
        instance.myDateTime = dateTimeNow.add(value: 4, to: .hour)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTimeTemporal_DateTime_now_addvalue1to_hourbetweenTemporalDateTimeTemporal_DateTime_now_addvalue3to_hourwith() throws {
        let dateTimeNow = Temporal.DateTime.now()
        let predicate = QPredGen.keys.myDateTime.between(start: dateTimeNow.add(value: 1, to: .hour), end: dateTimeNow.add(value: 3, to: .hour))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
