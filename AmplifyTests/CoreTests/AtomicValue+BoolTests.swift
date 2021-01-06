//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueBoolTests: XCTestCase {

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
