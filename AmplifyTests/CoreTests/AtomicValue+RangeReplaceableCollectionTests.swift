//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class AtomicValueRangeReplaceableTests: XCTestCase {

    func testAppend() {
        let atomicArray = AtomicValue(initialValue: [Int]())

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            atomicArray.append(iteration)
        }

        XCTAssertEqual(atomicArray.get().count, 10_000)
    }

    func testAppendContentsOf() {
        let atomicArray = AtomicValue(initialValue: [Int]())

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            let newArray = [iteration, iteration * 2]
            atomicArray.append(contentsOf: newArray)
        }

        XCTAssertEqual(atomicArray.get().count, 20_000)
    }

    func testRemoveFirst() {
        let initialValue = [Int](repeating: 1, count: 10_000)
        let atomicArray = AtomicValue(initialValue: initialValue)

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            _ = atomicArray.removeFirst()
        }

        XCTAssertEqual(atomicArray.get().count, 0)
    }

    func testSubscript() {
        let atomicInt = AtomicValue(initialValue: 0)

        let arrayValue = [Int](repeating: 2, count: 10_000)
        let atomicArray = AtomicValue(initialValue: arrayValue)

        DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
            let value = atomicArray[iteration]
            _ = atomicInt.increment(by: value)
        }

        XCTAssertEqual(atomicInt.get(), 20_000)
    }
}
