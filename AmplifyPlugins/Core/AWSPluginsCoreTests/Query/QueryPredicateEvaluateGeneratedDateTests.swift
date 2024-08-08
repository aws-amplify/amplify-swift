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
class QueryPredicateEvaluateGeneratedDateTests: XCTestCase {
    func testTemporalDateTemporal_Date_nownotEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nownotEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nownotEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nownotEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nownotEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daynotEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daynotEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daynotEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daynotEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daynotEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daynotEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daynotEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daynotEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daynotEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daynotEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daynotEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daynotEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daynotEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daynotEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daynotEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ne(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowequalsTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowequalsTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowequalsTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowequalsTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowequalsTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_dayequalsTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_dayequalsTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_dayequalsTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_dayequalsTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_dayequalsTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_dayequalsTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_dayequalsTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_dayequalsTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_dayequalsTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_dayequalsTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_dayequalsTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_dayequalsTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_dayequalsTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_dayequalsTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_dayequalsTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.eq(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.le(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowlessThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daylessThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daylessThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daylessThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.lt(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterOrEqualTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterOrEqualTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterOrEqualTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.ge(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now())
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_nowgreaterThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now())
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 1, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue1to_daygreaterThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 1, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 2, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue2to_daygreaterThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 2, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterThanTemporalDateTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterThanTemporalDateTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterThanTemporalDateTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterThanTemporalDateTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testTemporalDateTemporal_Date_now_addvalue3to_daygreaterThanTemporalDate() throws {
        let predicate = QPredGen.keys.myDate.gt(Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywithTemporal_Date_now() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now()

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywithTemporal_Date_now_addvalue1to_day() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 1, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywithTemporal_Date_now_addvalue2to_day() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 2, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywithTemporal_Date_now_addvalue3to_day() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 3, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssert(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywithTemporal_Date_now_addvalue4to_day() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        var instance = QPredGen(name: "test")
        instance.myDate = Temporal.Date.now().add(value: 4, to: .day)

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }

    func testbetweenTemporalDateTemporal_Date_now_addvalue1to_daybetweenTemporalDateTemporal_Date_now_addvalue3to_daywith() throws {
        let predicate = QPredGen.keys.myDate.between(start: Temporal.Date.now().add(value: 1, to: .day), end: Temporal.Date.now().add(value: 3, to: .day))
        let instance = QPredGen(name: "test")

        let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)

        XCTAssertFalse(evaluation)
    }
}
