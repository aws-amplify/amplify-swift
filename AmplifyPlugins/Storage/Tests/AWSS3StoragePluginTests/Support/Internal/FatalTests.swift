//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyTestCommon
@testable import Amplify
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class FatalTests: XCTestCase, @unchecked Sendable {

    func testFatalMustOverride() throws {
        try XCTAssertThrowFatalError { Fatal.mustOverride() }
    }

    func testFatalUnreachable() throws {
        try XCTAssertThrowFatalError { Fatal.unreachable("Testing") }
    }

    func testFatalNotImplemented() throws {
        try XCTAssertThrowFatalError { Fatal.notImplemented("Testing") }
    }

    func testFatalRequired() throws {
        try XCTAssertThrowFatalError { Fatal.require("Testing") }
    }

    func testFatalTODO() throws {
        try XCTAssertThrowFatalError { Fatal.TODO("Testing") }
    }

    func testFatalError() throws {
        try XCTAssertThrowFatalError { Fatal.error("Testing") }
    }

}
