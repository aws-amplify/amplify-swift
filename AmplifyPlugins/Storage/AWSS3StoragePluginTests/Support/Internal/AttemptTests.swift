//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyTestCommon
@testable import AWSS3StoragePlugin
@testable import Amplify

class AttemptTests: XCTestCase {
    let goodNumber = 42
    let badNumber = 13

    func testAttemptWithReturnSomething() throws {
        var error: Error?
        let result = attempt(try work1(number: goodNumber)) {
            error = $0
        }
        XCTAssertNil(error)
        XCTAssertEqual(goodNumber, result)
    }

    func testAttemptWithReturnNothing() throws {
        var error: Error?
        let result = attempt(try work1(number: badNumber)) {
            error = $0
        }
        XCTAssertNotNil(error)
        XCTAssertNil(result)
    }

    func testAttemptNoThrow() throws {
        let result = attempt(try work2(number: goodNumber)) {
            XCTFail("Error: \($0)")
        }
        XCTAssertEqual(true, result)
    }

    func testAttemptThrow() throws {
        let result = attempt(try work2(number: badNumber)) {
            print("Error: \($0)")
        }
        XCTAssertEqual(false, result)
    }

    func testAttemptNoFailClosureNoThrow() throws {
        let result = attempt(try work1(number: badNumber))
        XCTAssertNil(result)
    }

    func testAttemptNoFailClosureThrow() throws {
        let result = attempt(try work2(number: badNumber))
        XCTAssertEqual(false, result)
    }

    // MARK: - Support Functions -

    enum Failure: Error {
        case badNumber
    }

    private func work1(number: Int) throws -> Int {
        if number == badNumber {
            throw Failure.badNumber
        }
        return number
    }

    private func work2(number: Int) throws {
        if number == badNumber {
            throw Failure.badNumber
        }
    }

}
