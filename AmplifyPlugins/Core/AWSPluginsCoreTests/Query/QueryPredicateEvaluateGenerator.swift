//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

let dateNow = Date()
let dateNowPlus1hour = dateNow.addingTimeInterval(60 * 60 * 1)
let dateNowPlus2hour = dateNow.addingTimeInterval(60 * 60 * 2)
let dateNowPlus3hour = dateNow.addingTimeInterval(60 * 60 * 3)
let dateNowPlus4hour = dateNow.addingTimeInterval(60 * 60 * 4)

let dateNowPlus1day = dateNow.addingTimeInterval(60 * 60 * 1 * 24)
let dateNowPlus2day = dateNow.addingTimeInterval(60 * 60 * 2 * 24)
let dateNowPlus3day = dateNow.addingTimeInterval(60 * 60 * 3 * 24)
let dateNowPlus4day = dateNow.addingTimeInterval(60 * 60 * 4 * 24)

// This is a generator that was used to generate the unit tests.
// This code was originally created as a standalone iphone app, but was moved into
// this unit test class so that it could be run by other developers

//swiftlint:disable type_body_length
//swiftlint:disable file_length
//swiftlint:disable line_length
//swiftlint:disable identifier_name
//swiftlint:disable function_parameter_count
class QueryPredicateGenerator: XCTestCase {
    func testBoolBool() throws {
        generate("Bool,Bool")
    }
    func testDoubleDouble() {
        generate("Double,Double")
    }
    func testDoubleInt() {
        generate("Double,Int")
    }
    func testIntDouble() {
        generate("Int,Double")
    }
    func testIntInt() {
        generate("Int,Int")
    }
    func testStringString() {
        generate("String,String")
    }
    func testDateDate() {
        generate("Temporal.Date,Temporal.Date")
    }
    func testDateTimeDateTime() {
        generate("Temporal.DateTime,Temporal.DateTime")
    }
    func testTimeTime() {
        generate("Temporal.Time,Temporal.Time")
    }

    let types: [String] = ["Bool", "Double", "Int", "String", "Temporal.Date", "Temporal.DateTime", "Temporal.Time"]
    let operations: [String] = ["notEqual", "equals", "lessOrEqual", "lessThan", "greaterOrEqual", "greaterThan", "contains", "between", "beginsWith"]
    var requestedList: [String: [String]] = [
        "Bool,Bool": ["notEqual", "equals"],
        "Double,Double": ["notEqual", "equals", "less", "greater", "between"],
        "Double,Int": ["notEqual", "equals", "less", "greater", "between"],
        "Int,Double": ["notEqual", "equals", "less", "greater", "between"],
        "Int,Int": ["notEqual", "equals", "less", "greater", "between"],
        "String,String": ["notEqual", "equals", "less", "greater", "contains", "between", "beginsWith"],

        "Temporal.Date,Temporal.Date": ["notEqual", "equals", "less", "greater", "between"],
        "Temporal.DateTime,Temporal.DateTime": ["notEqual", "equals", "less", "greater", "between"],
        "Temporal.Time,Temporal.Time": ["notEqual", "equals", "less", "greater", "between"]
    ]

    let operationMap: [String: String] = [
        "equals": "eq",
        "notEqual": "ne",
        "lessOrEqual": "le",
        "lessThan": "lt",
        "greaterOrEqual": "ge",
        "greaterThan": "gt",
        "contains": "contains",
        "between": "between",
        "beginsWith": "beginsWith"
    ]

    let typeToValuesMap: [String: [String]] = [
        "Bool": ["true", "false", ""],
        "Double": ["1.1", "2.1", "3.1", "1", "2", "3", ""],
        "Int": ["1", "2", "3", ""],
        "String": ["\"a\"", "\"bb\"", "\"aa\"", "\"c\"", ""],
        "Temporal.Date": ["Temporal.Date.now()",
                          "Temporal.Date.now().add(value:1, to:.day)",
                          "Temporal.Date.now().add(value:2, to:.day)",
                          "Temporal.Date.now().add(value:3, to:.day)",
                          ""],
        "Temporal.DateTime": ["Temporal.DateTime.now()",
                              "Temporal.DateTime.now().add(value:1, to:.hour)",
                              "Temporal.DateTime.now().add(value:2, to:.hour)",
                              "Temporal.DateTime.now().add(value:3, to:.hour)",
                              ""],
        "Temporal.Time": ["Temporal.Time.now()",
                          "Temporal.Time.now().add(value:1, to:.hour)",
                          "Temporal.Time.now().add(value:2, to:.hour)",
                          "Temporal.Time.now().add(value:3, to:.hour)",
                          ""]
    ]

    let temporalToTimeMap: [String: Date] = [
        "Temporal.Date.now()": dateNow,
        "Temporal.Date.now().add(value:1, to:.day)": dateNowPlus1day,
        "Temporal.Date.now().add(value:2, to:.day)": dateNowPlus2day,
        "Temporal.Date.now().add(value:3, to:.day)": dateNowPlus3day,
        "Temporal.Date.now().add(value:4, to:.day)": dateNowPlus4day,

        "Temporal.DateTime.now()": dateNow,
        "Temporal.DateTime.now().add(value:1, to:.hour)": dateNowPlus1hour,
        "Temporal.DateTime.now().add(value:2, to:.hour)": dateNowPlus2hour,
        "Temporal.DateTime.now().add(value:3, to:.hour)": dateNowPlus3hour,
        "Temporal.DateTime.now().add(value:4, to:.hour)": dateNowPlus4hour,

        "Temporal.Time.now()": dateNow,
        "Temporal.Time.now().add(value:1, to:.hour)": dateNowPlus1hour,
        "Temporal.Time.now().add(value:2, to:.hour)": dateNowPlus2hour,
        "Temporal.Time.now().add(value:3, to:.hour)": dateNowPlus3hour,
        "Temporal.Time.now().add(value:4, to:.hour)": dateNowPlus4hour
    ]

    let typePairTov1v2BetweenTestsMap = [
        "Double,Double": [("1.1", "3.1"), ("1", "3")],
        "Double,Int": [("1.1", "3"), ("1", "3")],
        "Int,Double": [("1", "3.1"), ("1", "3")],
        "Int,Int": [("1", "3")],
        "String,String": [("\"bb\"", "\"dd\"")],
        "Temporal.Date,Temporal.Date": [("Temporal.Date.now().add(value:1, to:.day)", "Temporal.Date.now().add(value:3, to:.day)")],
        "Temporal.DateTime,Temporal.DateTime": [("Temporal.DateTime.now().add(value:1, to:.hour)", "Temporal.DateTime.now().add(value:3, to:.hour)")],
        "Temporal.Time,Temporal.Time": [("Temporal.Time.now().add(value:1, to:.hour)", "Temporal.Time.now().add(value:3, to:.hour)")]
    ]

    //the type of v3 is the type of v1 (which is the first part of the key)
    let typePairTov3BetweenTestsMap = [
        "Double,Double": ["0", "0.0", "1.1", "2", "1.2", "3", "3.1", "3.2", "4", ""],
        "Double,Int": ["0", "0.0", "1.1", "2", "1.2", "3", "3.1", "3.2", "4", ""],
        "Int,Double": ["0", "1", "2", "3", "4", ""],
        "Int,Int": ["0", "1", "2", "3", "4", ""],
        "String,String": ["\"a\"", "\"bb\"", "\"c\"", "\"dd\"", "\"e\"", ""],
        "Temporal.Date,Temporal.Date": ["Temporal.Date.now()",
                                        "Temporal.Date.now().add(value:1, to:.day)",
                                        "Temporal.Date.now().add(value:2, to:.day)",
                                        "Temporal.Date.now().add(value:3, to:.day)",
                                        "Temporal.Date.now().add(value:4, to:.day)",
                                        ""],
        "Temporal.DateTime,Temporal.DateTime": ["Temporal.DateTime.now()",
                                                "Temporal.DateTime.now().add(value:1, to:.hour)",
                                                "Temporal.DateTime.now().add(value:2, to:.hour)",
                                                "Temporal.DateTime.now().add(value:3, to:.hour)",
                                                "Temporal.DateTime.now().add(value:4, to:.hour)",
                                                ""],
        "Temporal.Time,Temporal.Time": ["Temporal.Time.now()",
                                        "Temporal.Time.now().add(value:1, to:.hour)",
                                        "Temporal.Time.now().add(value:2, to:.hour)",
                                        "Temporal.Time.now().add(value:3, to:.hour)",
                                        "Temporal.Time.now().add(value:4, to:.hour)",
                                        ""]
    ]

    let fieldForType: [String: String] = [
        "Bool": "myBool",
        "Double": "myDouble",
        "Int": "myInt",
        "String": "myString",
        "Temporal.Date": "myDate",
        "Temporal.DateTime": "myDateTime",
        "Temporal.Time": "myTime"
    ]

    func generate(_ filter: String, printCount: Bool = false) {
        var count = 0
        for t1 in types {
            for t2 in types {
                for operation in operations {
                    let key = "\(t1),\(t2)"
                    if key != filter {
                        continue
                    }
                    if let requestedOperations = requestedList[key] {
                        for requestedOperation in requestedOperations {
                            if operation.contains(requestedOperation) {
                                count += performGeneration(t1: t1, t2: t2, operation: operation)
                            }
                        }
                    }
                }
            }
        }
        if printCount {
            print("numberOfFunctions=\(count)")
        }
    }

    func performGeneration(t1: String, t2: String, operation: String) -> Int {
        var count = 0
        guard let values1 = typeToValuesMap[t1],
            let values2 = typeToValuesMap[t2] else {
                print("failed to find values map!")
                exit(1)
        }
        if operation == "between" {
            let key = "\(t1),\(t2)"
            let v1v2s = typePairTov1v2BetweenTestsMap[key]!
            let v3s = typePairTov3BetweenTestsMap[key]!
            for (v1, v2) in v1v2s {
                for v3 in v3s {
                    if handleBetween(t1: t1, v1: v1, t2: t2, v2: v2, v3: v3, operation: operation) {
                        count += 1
                    }
                }
            }
        } else {
            if t1 == "Int" && t2 == "Double" {
                //Unable to assign a double value to a Int Type, so these tests are invalid
                return 0
            }
            for v1 in values1 {
                if v1 == "" {
                    continue
                }
                for v2 in values2 {
                    if handleOtherOperations(t1: t1, v1: v1, t2: t2, v2: v2, operation: operation) {
                        count += 1
                    }
                }
            }

        }
        return count
    }

    // handleBetween generates a test to check if v3 (value3) is between v1 and v2
    func handleBetween(t1: String, v1: String, t2: String, v2: String, v3: String, operation: String) -> Bool {
        guard let op = operationMap[operation],
            let fieldName = fieldForType[t1] else {
                print("Failed to look up operation")
                return false
        }

        let v1FnName = v1.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let v2FnName = v2.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        let type1 = t1.replacingOccurrences(of: ".", with: "")
        let type2 = t2.replacingOccurrences(of: ".", with: "")

        //In cases of between, we should check we have v1, v2 and v3, E.g.: (v1 < v3 && v3 > v2)
        if v2 == "" {
            return false
        }

        let v3FnName = v3.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        print("func test\(operation)\(type1)\(v1FnName)\(operation)\(type2)\(v2FnName)with\(v3FnName)() throws {")

        if t1 == "Temporal.DateTime" {
            print("   let dateTimeNow = Temporal.DateTime.now()")
        } else if t1 == "Temporal.Time" {
            print("   let timeNow = try Temporal.Time.init(iso8601String: \"10:16:44\")")
        }
        let v1LocalRef = v1.replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v2LocalRef = v2.replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v3LocalRef = v3.replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")

        print("   let predicate = QPredGen.keys.\(fieldName).\(op)(start: \(v1LocalRef), end: \(v2LocalRef))")
        if v3 != "" {
            print("   var instance = QPredGen(name: \"test\")")
            print("   instance.\(fieldName) = \(v3LocalRef)")
        } else {
            print("   let instance = QPredGen(name: \"test\")")
        }
        print("")
        print("   let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)")
        print("")
        if type1 == "String" {
            if attemptToResolveBetweenString(v1, v2, v3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        } else if type1.contains("Temporal") {
            if attemptToResolveBetweenTemporal(t1, v1, t2, v2, v3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        } else {
            if attemptToResolveBetweenDouble(v1, v2, v3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        }
        print("}")
        print("")
        return true
    }

    func handleOtherOperations(t1: String, v1: String, t2: String, v2: String, operation: String) -> Bool {
        guard let op = operationMap[operation],
            let fieldName = fieldForType[t1] else {
                print("Failed to look up operation")
                return false
        }

        let v1FnName = v1.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let v2FnName = v2.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let type1 = t1.replacingOccurrences(of: ".", with: "")
        let type2 = t2.replacingOccurrences(of: ".", with: "")

        print("func test\(type1)\(v1FnName)\(operation)\(type2)\(v2FnName)() throws {")
        if t1 == "Temporal.DateTime" {
            print("   let dateTimeNow = Temporal.DateTime.now()")
        } else if t1 == "Temporal.Time" {
            print("   let timeNow = try Temporal.Time.init(iso8601String: \"10:16:44\")")
        }
        let v1LocalRef = v1.replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v2LocalRef = v2.replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")

        print("   let predicate = QPredGen.keys.\(fieldName).\(op)(\(v1LocalRef))")

        if v2LocalRef != "" {
            print("   var instance = QPredGen(name: \"test\")")
            print("   instance.\(fieldName) = \(v2LocalRef)")
        } else {
            print("   let instance = QPredGen(name: \"test\")")
        }
        print("")
        print("   let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)")
        print("")

        if attemptToResolve(type1,
                            v1.replacingOccurrences(of: "\"", with: ""), type2,
                            v2.replacingOccurrences(of: "\"", with: ""), op) {
            print("   XCTAssert(evaluation)")
        } else {
            print("   XCTAssertFalse(evaluation)")
        }
        print("}")
        print("")
        return true
    }

    func attemptToResolve(_ t1: String, _ v1: String,
                          _ t2: String, _ v2: String,
                          _ op: String) -> Bool {
        if t1 == "Double" && t2 == "Int" ||
            t1 == "Int" && t2 == "Double" ||
            t1 == "Double" && t2 == "Double" ||
            t1 == "Int" && t2 == "Int" {
            return attemptToResolveNumeric(t1, v1, t2, v2, op)
        }
        if t1.contains("Temporal") {
            return attemptToResolveTemporal(t1, v1, t2, v2, op)
        }

        if v2 == "" {
            return false
        }
        switch op {
        case "eq":
            return v2 == v1
        case "ne":
            return v2 != v1
        case "le":
            return v2 <= v1
        case "lt":
            return v2 < v1
        case "ge":
            return v2 >= v1
        case "gt":
            return v2 > v1
        case "between":
            print("FAILED: THIS FUNCTION SHOULD NOT BE CALLED WITH BETWEEN")
            return false
        case "beginsWith":
            return v2.starts(with: v1)
        case "contains":
            return v2.contains(v1)
        default:
            print("FAILED: THIS FUNCTION SHOULD NOT BE CALLED WITH: \(op)")
            return false
        }
    }

    func attemptToResolveNumeric(_ t1: String, _ sv1: String,
                                 _ t2: String, _ sv2: String,
                                 _ op: String) -> Bool {
        if sv2 == "" {
            return false
        }

        guard let v1 = Double(sv1),
            let v2 = Double(sv2) else {
                print("FAILED NUMERIC!")
                return false
        }

        switch op {
        case "eq":
            return v2 == v1
        case "ne":
            return v2 != v1
        case "le":
            return v2 <= v1
        case "lt":
            return v2 < v1
        case "ge":
            return v2 >= v1
        case "gt":
            return v2 > v1
        case "between":
            print("FATAL ERROR DO NOT ENTER!")
        case "beginsWith":
            return false
        default:
            return false
        }
        return false
    }

    func attemptToResolveTemporal(_ t1: String, _ sv1: String,
                                  _ t2: String, _ sv2: String,
                                  _ op: String) -> Bool {
        if sv2 == "" {
            return false
        }

        //Use built-in Date to determine the assert logic
        let v1 = temporalToTimeMap[sv1]!
        let v2 = temporalToTimeMap[sv2]!

        switch op {
        case "eq":
            return v2 == v1
        case "ne":
            return v2 != v1
        case "le":
            return v2 <= v1
        case "lt":
            return v2 < v1
        case "ge":
            return v2 >= v1
        case "gt":
            return v2 > v1
        case "between":
            print("FATAL: between Temporal")
        case "beginsWith":
            print("FATAL: beginsWith Temporal")
            return false
        default:
            return false
        }
        return false
    }

    func attemptToResolveBetweenTemporal(_ st1: String, _ sv1: String,
                                         _ st2: String, _ sv2: String,
                                         _ sv3: String) -> Bool {
        if sv3 == "" {
            return false
        }
        //Use built-in Date to determine the assert logic
        let v1 = temporalToTimeMap[sv1]!
        let v2 = temporalToTimeMap[sv2]!
        let v3 = temporalToTimeMap[sv3]!
        return v1 < v3 && v2 > v3
    }

    func attemptToResolveBetweenDouble(_ sv1: String,
                                       _ sv2: String,
                                       _ sv3: String) -> Bool {
        if sv3 == "" {
            return false
        }

        guard let v1 = Double(sv1),
            let v2 = Double(sv2),
            let v3 = Double(sv3) else {
                print("FAILED DOUBLE!")
                return false
        }
        return v1 < v3 && v2 > v3

    }
    func attemptToResolveBetweenString(_ sv1: String,
                                       _ sv2: String,
                                       _ sv3: String) -> Bool {
        return sv1 < sv3 && sv2 > sv3
    }
}
