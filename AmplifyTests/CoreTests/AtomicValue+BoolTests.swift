//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AtomicValueBoolTests: XCTestCase, @unchecked Sendable {

    func testGetAndToggleStartingWithTrue() {
        let atomicBool = AtomicValue(initialValue: true)
        XCTAssertEqual(atomicBool.getAndToggle(), true)
        XCTAssertEqual(atomicBool.get(), false)
    }

    func testGetAndToggleStartingWithFalse() {
        let atomicBool = AtomicValue(initialValue: false)
        XCTAssertEqual(atomicBool.getAndToggle(), false)
        XCTAssertEqual(atomicBool.get(), true)
    }

}
