//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class SynchronizedDictionaryTests: XCTestCase {

    /// Given: A SynchronizedDictionary
    /// When:
    /// - I `get` a nonexistent key
    /// Then: It returns a nil value and does not crash
    func testRetrieveNonExistentKey() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        XCTAssertNil(synchronizedDictionary.getValue(forKey: 0))
    }

    /// Given: A SynchronizedDictionary
    /// When:
    /// - I `get` an existing key
    /// Then: It returns the value associated with that key
    func testRetrieveExistingKey() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        synchronizedDictionary.set(value: 0, forKey: 0)
        XCTAssertEqual(synchronizedDictionary.getValue(forKey: 0), 0)
    }

    /// Given: A SynchronizedDictionary
    /// When: I add items
    /// Then: It maintains state in a thread safe way, and does not crash
    func testAdd() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }

        XCTAssertEqual(synchronizedDictionary.count, 5_000)
    }

    /// Given: A populated SynchronizedDictionary
    /// When: I remove items
    /// Then: It maintains state in a thread safe way, and does not crash
    func testRemove() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }

        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            synchronizedDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(synchronizedDictionary.count, 4_000)
    }

    /// Given: A populated SynchronizedDictionary
    /// When: I invoke `removeAll`
    /// Then: The dictionary is empty
    func testRemoveAll() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }
        synchronizedDictionary.removeAll()
        XCTAssertEqual(synchronizedDictionary.count, 0)
    }

    /// Given: A populated SynchronizedDictionary
    /// When:
    /// - I get the keys of the dictionary
    /// - Then remove elements
    /// Then: My local copy of keys has all of the original values
    func testKeys() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }

        let keys = synchronizedDictionary.keys
        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            synchronizedDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(keys.count, 5_000)
    }

    /// Given: A populated SynchronizedDictionary
    /// When:
    /// - I get the values of the dictionary
    /// - Then remove elements
    /// Then: My local copy of values has all of the original values
    func testValues() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }

        let values = synchronizedDictionary.values
        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            synchronizedDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(values.count, 5_000)
    }

    /// Given: A populated SynchronizedDictionary
    /// When:
    /// - I concurrently mutate the dictionary by changing values, adding new elements, and removing elements
    /// Then: It maintains state in a thread safe way, and does not crash
    func testConcurrentModifications() {
        let synchronizedDictionary = SynchronizedDictionary<Int, Int>()

        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.concurrentPerform(iterations: 6_000) { iteration in
            synchronizedDictionary.set(value: iteration, forKey: iteration)
        }

        let newIdCounter = AtomicValue(initialValue: 5_999)

        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: 6_000) { iteration in
                switch iteration {
                case 0 ..< 2_000:
                    synchronizedDictionary.removeValue(forKey: iteration)
                case 2_000 ..< 4_000:
                    synchronizedDictionary.set(value: -iteration, forKey: iteration)
                default:
                    // Let the element at this key stay as-is, but add a new element
                    let newId = newIdCounter.increment()
                    synchronizedDictionary.set(value: newId, forKey: newId)
                }
            }
            semaphore.signal()
        }

        semaphore.wait()

        // Expect each of these elements to be nil
        for key in 0 ..< 2_000 {
            XCTAssertNil(synchronizedDictionary.getValue(forKey: key))
        }

        for key in 2_000 ..< 4_000 {
            XCTAssertEqual(synchronizedDictionary.getValue(forKey: key), -key)
        }

        for key in 4_000 ..< 6_000 {
            XCTAssertEqual(synchronizedDictionary.getValue(forKey: key), key)
        }

        for key in 6_000 ..< 8_000 {
            XCTAssertEqual(synchronizedDictionary.getValue(forKey: key), key)
        }
    }

}
