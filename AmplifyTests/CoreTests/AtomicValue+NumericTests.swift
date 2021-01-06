//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueNumericTests: XCTestCase {

    func testIncrement() {
        let atomicInt = AtomicValue(initialValue: 0)

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            _ = atomicInt.increment()
        }

        XCTAssertEqual(atomicInt.get(), 10_000)
    }

    func testDecrement() {
        let atomicInt = AtomicValue(initialValue: 0)

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            _ = atomicInt.decrement()
        }

        XCTAssertEqual(atomicInt.get(), -10_000)
    }

}
