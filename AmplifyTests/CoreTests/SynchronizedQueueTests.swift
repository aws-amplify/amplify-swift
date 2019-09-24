//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class SynchronizedQueueTests: XCTestCase {

    /// Given: An empty SynchronizedQueue
    /// When:
    /// - I invoke `next()`
    /// Then: It returns a nil value and does not crash
    func testNextOnEmpty() {
        let synchronizedQueue = SynchronizedQueue<Int>()
        XCTAssertNil(synchronizedQueue.next())
    }

    /// Given: A SynchronizedQueue
    /// When:
    /// - I invoke `add()`
    /// - I invoke `next()`
    /// Then: The element is added and subsequently retrieved with `next()`
    func testSingleAddAndNext() {
        let synchronizedQueue = SynchronizedQueue<Int>()
        synchronizedQueue.add(-1)
        XCTAssertEqual(synchronizedQueue.count, 1)
        XCTAssertEqual(synchronizedQueue.next(), -1)
    }

    /// Given: A SynchronizedQueue with one element
    /// When:
    /// - I invoke `next()`
    /// Then: The element is removed from the queue
    func testNextRemovesItem() {
        let synchronizedQueue = SynchronizedQueue<Int>()
        synchronizedQueue.add(-1)
        XCTAssertEqual(synchronizedQueue.next(), -1)
        XCTAssertEqual(synchronizedQueue.count, 0)
    }

    /// Given: A SynchronizedQueue
    /// When: I add items from multiple threads
    /// Then: It maintains state in a thread safe way, and does not crash
    func testConcurrentAdd() {
        let synchronizedQueue = SynchronizedQueue<Int>()
        DispatchQueue.concurrentPerform(iterations: 5000) { iteration in
            synchronizedQueue.add(iteration)
        }

        // Note that we can't assert the order in which these were actually added since `concurrentPerform` doesn't
        // assert that work is performed serially
        XCTAssertEqual(synchronizedQueue.count, 5000)
    }

    /// Given: A populated SynchronizedQueue
    /// When: I add items from multiple threads
    /// Then: It maintains state in a thread safe way, and does not crash
    func testConcurrentDrain() {
        let synchronizedQueue = SynchronizedQueue<Int>()
        DispatchQueue.concurrentPerform(iterations: 5000) { iteration in
            synchronizedQueue.add(iteration)
        }

        DispatchQueue.concurrentPerform(iterations: 5000) { _ in
            _ = synchronizedQueue.next()
        }

        XCTAssertEqual(synchronizedQueue.count, 0)
    }

    /// Given: A SynchronizedQueue
    /// When: I add and remove items from multiple threads
    /// Then: It maintains state in a thread safe way, and does not crash
    func testConcurrentModifications() {
        let synchronizedQueue = SynchronizedQueue<Int>()

        let allElementsAreAdded = AtomicValue(initialValue: false)

        let allChecksAreComplete = expectation(description: "All checks are complete")

        DispatchQueue.global().async {
            while !allElementsAreAdded.get() || !synchronizedQueue.isEmpty {
                _ = synchronizedQueue.next()
            }
            allChecksAreComplete.fulfill()
        }

        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: 5000) { iteration in
                synchronizedQueue.add(iteration)
            }
            allElementsAreAdded.set(true)
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertEqual(synchronizedQueue.count, 0)
    }

}
