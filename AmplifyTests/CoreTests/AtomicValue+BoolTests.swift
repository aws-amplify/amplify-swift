//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueBoolTests: XCTestCase {

    func testGetAndToggle() {
        let atomicBool = AtomicValue(initialValue: true)
        XCTAssertEqual(atomicBool.getAndToggle(), true)
        XCTAssertEqual(atomicBool.get(), false)
    }

}
