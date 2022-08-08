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

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable function_parameter_count
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
        "Double,Double": ["0", "0.0", "1", "1.1", "2", "1.2", "3", "3.1", "3.2", "4", ""],
        "Double,Int": ["0", "0.0", "1", "1.1", "2", "1.2", "3", "3.1", "3.2", "4", ""],
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
        for type1 in types {
            for type2 in types {
                for operation in operations {
                    let key = "\(type1),\(type2)"
                    if key != filter {
                        continue
                    }
                    if let requestedOperations = requestedList[key] {
                        for requestedOperation in requestedOperations {
                            if operation.contains(requestedOperation) {
                                count += performGeneration(type1: type1, type2: type2, operation: operation)
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

    func performGeneration(type1: String, type2: String, operation: String) -> Int {
        var count = 0
        guard let values1 = typeToValuesMap[type1],
            let values2 = typeToValuesMap[type2] else {
                print("failed to find values map!")
                exit(1)
        }
        if operation == "between" {
            let key = "\(type1),\(type2)"
            let v1v2s = typePairTov1v2BetweenTestsMap[key]!
            let val3s = typePairTov3BetweenTestsMap[key]!
            for (val1, val2) in v1v2s {
                for val3 in val3s {
                    if handleBetween(type1: type1, val1: val1, type2: type2, val2: val2, val3: val3, operation: operation) {
                        count += 1
                    }
                }
            }
        } else {
            if type1 == "Int" && type2 == "Double" {
                //Unable to assign a double value to a Int Type, so these tests are invalid
                return 0
            }
            for val1 in values1 {
                if val1 == "" {
                    continue
                }
                for val2 in values2 {
                    if handleOtherOperations(type1: type1, val1: val1, type2: type2, val2: val2, operation: operation) {
                        count += 1
                    }
                }
            }

        }
        return count
    }

    // handleBetween generates a test to check if v3 (value3) is between v1 and v2
    func handleBetween(type1: String, val1: String, type2: String, val2: String, val3: String, operation: String) -> Bool {
        guard let oper = operationMap[operation],
            let fieldName = fieldForType[type1] else {
                print("Failed to look up operation")
                return false
        }

        let v1FnName = val1
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let v2FnName = val2
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        let type1 = type1.replacingOccurrences(of: ".", with: "")
        let type2 = type2.replacingOccurrences(of: ".", with: "")

        //In cases of between, we should check we have v1, v2 and v3, E.g.: (v1 < v3 && v3 > v2)
        if val2 == "" {
            return false
        }

        let v3FnName = val3.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        print("func test\(operation)\(type1)\(v1FnName)\(operation)\(type2)\(v2FnName)with\(v3FnName)() throws {")

        if type1 == "TemporalDateTime" {
            print("   let dateTimeNow = Temporal.DateTime.now()")
        } else if type1 == "TemporalTime" {
            print("   let timeNow = try Temporal.Time.init(iso8601String: \"10:16:44\")")
        }
        let v1LocalRef = val1
            .replacingOccurrences(of: "Temporal.DateTime.now()",
                                  with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v2LocalRef = val2
            .replacingOccurrences(of: "Temporal.DateTime.now()",
                                  with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v3LocalRef = val3
            .replacingOccurrences(of: "Temporal.DateTime.now()",
                                  with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")

        print("   let predicate = QPredGen.keys.\(fieldName).\(oper)(start: \(v1LocalRef), end: \(v2LocalRef))")
        if val3 != "" {
            print("   var instance = QPredGen(name: \"test\")")
            print("   instance.\(fieldName) = \(v3LocalRef)")
        } else {
            print("   let instance = QPredGen(name: \"test\")")
        }
        print("")
        print("   let evaluation = try predicate.evaluate(target: instance.eraseToAnyModel().instance)")
        print("")
        if type1 == "String" {
            if attemptToResolveBetweenString(val1, val2, val3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        } else if type1.contains("Temporal") {
            if attemptToResolveBetweenTemporal(type1, val1, type2, val2, val3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        } else {
            if attemptToResolveBetweenDouble(val1, val2, val3) {
                print("   XCTAssert(evaluation)")
            } else {
                print("   XCTAssertFalse(evaluation)")
            }
        }
        print("}")
        print("")
        return true
    }

    func handleOtherOperations(type1: String, val1: String, type2: String, val2: String, operation: String) -> Bool {
        guard let oper = operationMap[operation],
            let fieldName = fieldForType[type1] else {
                print("Failed to look up operation")
                return false
        }

        let v1FnName = val1
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let v2FnName = val2
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        let type1 = type1.replacingOccurrences(of: ".", with: "")
        let type2 = type2.replacingOccurrences(of: ".", with: "")

        print("func test\(type1)\(v1FnName)\(operation)\(type2)\(v2FnName)() throws {")
        if type1 == "TemporalDateTime" {
            print("   let dateTimeNow = Temporal.DateTime.now()")
        } else if type1 == "TemporalTime" {
            print("   let timeNow = try Temporal.Time.init(iso8601String: \"10:16:44\")")
        }
        let v1LocalRef = val1
            .replacingOccurrences(of: "Temporal.DateTime.now()",
                                  with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")
        let v2LocalRef = val2
            .replacingOccurrences(of: "Temporal.DateTime.now()",
                                                 with: "dateTimeNow")
            .replacingOccurrences(of: "Temporal.Time.now()",
                                  with: "timeNow")

        print("   let predicate = QPredGen.keys.\(fieldName).\(oper)(\(v1LocalRef))")

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
                            val1.replacingOccurrences(of: "\"", with: ""), type2,
                            val2.replacingOccurrences(of: "\"", with: ""), oper) {
            print("   XCTAssert(evaluation)")
        } else {
            print("   XCTAssertFalse(evaluation)")
        }
        print("}")
        print("")
        return true
    }

    func attemptToResolve(_ type1: String, _ val1: String,
                          _ type2: String, _ val2: String,
                          _ operation: String) -> Bool {
        if val2 == "" {
            return false
        }

        if type1 == "Double" && type2 == "Int" ||
            type1 == "Int" && type2 == "Double" ||
            type1 == "Double" && type2 == "Double" ||
            type1 == "Int" && type2 == "Int" {
            return attemptToResolveNumeric(type1, val1, type2, val2, operation)
        } else if type1.contains("Temporal") {
            return attemptToResolveTemporal(type1, val1, type2, val2, operation)
        } else if (type1 == "String" && type2 == "String") ||
            (type1 == "Bool" && type2 == "Bool") {
            return attemptToResolveStringBool(val1, val2, operation)
        }
        print("attemptToResolve: FAILED TO DETECT TYPES!")
        return false
    }

    func attemptToResolveStringBool(_ val1: String,
                                    _ val2: String,
                                    _ operation: String) -> Bool {
        let rhs = val1
        let lhs = val2
        switch operation {
        case "eq":
            return lhs == rhs
        case "ne":
            return lhs != rhs
        case "le":
            return lhs <= rhs
        case "lt":
            return lhs < rhs
        case "ge":
            return lhs >= rhs
        case "gt":
            return lhs > rhs
        case "beginsWith":
            return lhs.starts(with: rhs)
        case "contains":
            return lhs.contains(rhs)
        default:
            print("FAILED attemptToResolveString: THIS FUNCTION SHOULD NOT BE CALLED WITH: \(operation)")
            return false
        }
    }

    func attemptToResolveNumeric(_ type1: String, _ sv1: String,
                                 _ type2: String, _ sv2: String,
                                 _ operation: String) -> Bool {
        guard let val1 = Double(sv1),
            let val2 = Double(sv2) else {
                print("FAILED attemptToResolveNumeric")
                return false
        }

        let rhs = val1
        let lhs = val2
        switch operation {
        case "eq":
            return lhs == rhs
        case "ne":
            return lhs != rhs
        case "le":
            return lhs <= rhs
        case "lt":
            return lhs < rhs
        case "ge":
            return lhs >= rhs
        case "gt":
            return lhs > rhs
        case "beginsWith":
            return false
        default:
            print("FAILED attemptToResolveNumeric: THIS FUNCTION SHOULD NOT BE CALLED WITH: \(operation)")
            return false
        }
    }

    func attemptToResolveTemporal(_ type1: String, _ sv1: String,
                                  _ type2: String, _ sv2: String,
                                  _ operation: String) -> Bool {
        //Use built-in Date to determine the assert logic
        let val1 = temporalToTimeMap[sv1]!
        let val2 = temporalToTimeMap[sv2]!

        let rhs = val1
        let lhs = val2
        switch operation {
        case "eq":
            return lhs == rhs
        case "ne":
            return lhs != rhs
        case "le":
            return lhs <= rhs
        case "lt":
            return lhs < rhs
        case "ge":
            return lhs >= rhs
        case "gt":
            return lhs > rhs
        default:
            print("FAILED attemptToResolveTemporal: THIS FUNCTION SHOULD NOT BE CALLED WITH: \(operation)")
            return false
        }
    }

    func attemptToResolveBetweenTemporal(_ st1: String, _ sv1: String,
                                         _ st2: String, _ sv2: String,
                                         _ sv3: String) -> Bool {
        if sv3 == "" {
            return false
        }
        //Use built-in Date to determine the assert logic
        let val1 = temporalToTimeMap[sv1]!
        let val2 = temporalToTimeMap[sv2]!
        let val3 = temporalToTimeMap[sv3]!
        return val1 <= val3 && val2 >= val3
    }

    func attemptToResolveBetweenDouble(_ sv1: String,
                                       _ sv2: String,
                                       _ sv3: String) -> Bool {
        if sv3 == "" {
            return false
        }

        guard let val1 = Double(sv1),
            let val2 = Double(sv2),
            let val3 = Double(sv3) else {
                print("FAILED DOUBLE!")
                return false
        }
        return val1 <= val3 && val2 >= val3

    }

    func attemptToResolveBetweenString(_ sv1: String,
                                       _ sv2: String,
                                       _ sv3: String) -> Bool {
        return sv1 <= sv3 && sv2 >= sv3
    }
}
