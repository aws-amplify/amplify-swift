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

class FatalTests: XCTestCase {

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
