//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

class AtomicDictionaryTests: XCTestCase {

    func testPerformance() {
        let atomicDictionary = AtomicDictionary(initialValue: [Int: Int]())
        measure {
            DispatchQueue.concurrentPerform(iterations: 10_000) { iteration in
                atomicDictionary.set(value: iteration, forKey: iteration)
            }
        }
    }

    /// Given: An AtomicDictionary
    /// When:
    /// - I `get` a nonexistent key
    /// Then: It returns a nil value and does not crash
    func testRetrieveNonExistentKey() {
        let atomicDictionary = AtomicDictionary(initialValue: [Int: Int]())
        XCTAssertNil(atomicDictionary.getValue(forKey: 0))
    }

    /// Given: An AtomicDictionary
    /// When:
    /// - I `get` an existing key
    /// Then: It returns the value associated with that key
    func testRetrieveExistingKey() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        atomicDictionary.set(value: 0, forKey: 0)
        XCTAssertEqual(atomicDictionary.getValue(forKey: 0), 0)
    }

    /// Given: An AtomicDictionary
    /// When: I add items
    /// Then: It maintains state in a thread safe way, and does not crash
    func testAdd() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }

        XCTAssertEqual(atomicDictionary.count, 5_000)
    }

    /// Given: A populated AtomicDictionary
    /// When: I remove items
    /// Then: It maintains state in a thread safe way, and does not crash
    func testRemove() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }

        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            atomicDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(atomicDictionary.count, 4_000)
    }

    /// Given: A populated AtomicDictionary
    /// When: I invoke `removeAll`
    /// Then: The dictionary is empty
    func testRemoveAll() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }
        atomicDictionary.removeAll()
        XCTAssertEqual(atomicDictionary.count, 0)
    }

    /// Given: A populated AtomicDictionary
    /// When:
    /// - I get the keys of the dictionary
    /// - Then remove elements
    /// Then: My local copy of keys has all of the original values
    func testKeys() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }

        let keys = atomicDictionary.keys
        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            atomicDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(keys.count, 5_000)
    }

    /// Given: A populated AtomicDictionary
    /// When:
    /// - I get the values of the dictionary
    /// - Then remove elements
    /// Then: My local copy of values has all of the original values
    func testValues() {
        let atomicDictionary = AtomicDictionary<Int, Int>()
        DispatchQueue.concurrentPerform(iterations: 5_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }

        let values = atomicDictionary.values
        DispatchQueue.concurrentPerform(iterations: 1_000) { iteration in
            atomicDictionary.removeValue(forKey: iteration)
        }

        XCTAssertEqual(values.count, 5_000)
    }

    /// Given: A populated AtomicDictionary
    /// When:
    /// - I concurrently mutate the dictionary by changing values, adding new elements, and removing elements
    /// Then: It maintains state in a thread safe way, and does not crash
    func testConcurrentModifications() {
        let atomicDictionary = AtomicDictionary<Int, Int>()

        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.concurrentPerform(iterations: 6_000) { iteration in
            atomicDictionary.set(value: iteration, forKey: iteration)
        }

        let newIdCounter = AtomicValue(initialValue: 5_999)

        DispatchQueue.global().async {
            DispatchQueue.concurrentPerform(iterations: 6_000) { iteration in
                switch iteration {
                case 0 ..< 2_000:
                    atomicDictionary.removeValue(forKey: iteration)
                case 2_000 ..< 4_000:
                    atomicDictionary.set(value: -iteration, forKey: iteration)
                default:
                    // Let the element at this key stay as-is, but add a new element
                    let newId = newIdCounter.increment()
                    atomicDictionary.set(value: newId, forKey: newId)
                }
            }
            semaphore.signal()
        }

        semaphore.wait()

        // Expect each of these elements to be nil
        for key in 0 ..< 2_000 {
            XCTAssertNil(atomicDictionary.getValue(forKey: key))
        }

        for key in 2_000 ..< 4_000 {
            XCTAssertEqual(atomicDictionary.getValue(forKey: key), -key)
        }

        for key in 4_000 ..< 6_000 {
            XCTAssertEqual(atomicDictionary.getValue(forKey: key), key)
        }

        for key in 6_000 ..< 8_000 {
            XCTAssertEqual(atomicDictionary.getValue(forKey: key), key)
        }
    }

}
