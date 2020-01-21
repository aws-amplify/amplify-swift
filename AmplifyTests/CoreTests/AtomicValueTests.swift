//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueTests: XCTestCase {

    func testSimpleSet() {
        let atomicInt = AtomicValue(initialValue: -1)

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            _ = atomicInt.set(iteration)
        }

        XCTAssertNotEqual(atomicInt.get(), -1)
    }

    func testGetAndSet() {
        let atomicInt = AtomicValue(initialValue: -1)

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            _ = atomicInt.getAndSet(iteration)
        }

        XCTAssertNotEqual(atomicInt.get(), -1)
    }

    func testAtomicallyPerform() {
        let invocationCounter = InvocationCounter()
        let atomicInvocationCounter = AtomicValue(initialValue: invocationCounter)

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            atomicInvocationCounter.atomicallyPerform { $0.invoke() }
        }

        XCTAssertEqual(atomicInvocationCounter.get().invocationCount, 10_000)
    }

}

final class InvocationCounter {
    private(set) var invocationCount = 0

    func invoke() {
        invocationCount += 1
    }
}
