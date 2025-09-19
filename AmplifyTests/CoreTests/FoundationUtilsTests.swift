//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

class FoundationUtilsTests: XCTestCase {

    func test_isEmpty_extensionPlaysNicelyWithStandardLib_Array() {
        let notEmpty = ["Foo"]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String] = []
        XCTAssert(empty.isEmpty)
    }

    func test_isEmpty_extensionPlaysNicelyWithStandardLib_Dict() {
        let notEmpty = ["Foo": 1]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String: Int] = [:]
        XCTAssert(empty.isEmpty)
    }

    func test_isEmpty_String() {
        let notEmpty = "Foo"
        XCTAssertFalse(notEmpty.isEmpty)

        let empty = ""
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: String? = "Foo"
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: String? = ""
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: String? = nil
        XCTAssert(nilOptional.isEmpty)
    }

    func test_isEmpty_Array() {
        let notEmpty = ["Foo"]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String] = []
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: [String]? = ["Foo"]
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: [String]? = []
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: [String]? = nil
        XCTAssert(nilOptional.isEmpty)
    }

    func test_isEmpty_Dict() {
        let notEmpty = ["Foo": 1]
        XCTAssertFalse(notEmpty.isEmpty)

        let empty: [String: Int] = [:]
        XCTAssert(empty.isEmpty)

        let notEmptyOptional: [String: Int]? = ["Foo": 1]
        XCTAssertFalse(notEmptyOptional.isEmpty)

        let emptyOptional: [String: Int]? = [:]
        XCTAssert(emptyOptional.isEmpty)

        let nilOptional: [String: Int]? = nil
        XCTAssert(nilOptional.isEmpty)
    }

}
