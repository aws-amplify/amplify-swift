//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueTests: XCTestCase {

    func testPerformance() {
        let atomicInt = AtomicValue(initialValue: 0)
        measure {
            DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
                _ = atomicInt.increment()
            }
        }
    }

    func testSimpleSet() {
        let atomicInt = AtomicValue(initialValue: -1)

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            atomicInt.set(iteration)
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

    func testWith() {
        let atomicDict = AtomicValue(initialValue: [Int: Int]())

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            atomicDict.with { value in
                let bucket = iteration % 10
                if value[bucket] != nil {
                    value[bucket]! += 1
                } else {
                    value[bucket] = 1
                }
            }
        }

        for bucket in 0 ..< 10 {
            XCTAssertEqual(atomicDict.get()[bucket], 1_000)
        }
    }

    func testWithNullable() async {
        let deinitialized = expectation(description: "deinitialized")
        let atomicNotifier = AtomicValue<InvocationCounter?>(
            initialValue: InvocationCounter(fulfillingOnDeinit: deinitialized)
        )
        DispatchQueue.concurrentPerform(iterations: 1_000) { iter in
            if iter == 500 {
                atomicNotifier.with { $0 = nil }
            } else {
                atomicNotifier.atomicallyPerform { $0?.invoke() }
            }
        }

        await fulfillment(of: [deinitialized], timeout: 1)
    }
}

final class InvocationCounter {
    private(set) var invocationCount = 0
    private let deinitExpectation: XCTestExpectation?

    init(fulfillingOnDeinit deinitExpectation: XCTestExpectation? = nil) {
        self.deinitExpectation = deinitExpectation
    }

    func invoke() {
        invocationCount += 1
    }

    deinit {
        deinitExpectation?.fulfill()
    }
}
