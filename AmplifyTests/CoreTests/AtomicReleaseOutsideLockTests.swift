//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

/// A value released by an `AtomicDictionary` or `AtomicValue` mutator can run a `deinit` that uses the same
/// container, for example a Hub listener whose captured object removes that listener when it is released.
/// The locks are not reentrant, so the mutators must release what they replace after unlocking.
// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AtomicReleaseOutsideLockTests: XCTestCase, @unchecked Sendable {

    /// `removeAll` releases the removed values after unlocking
    ///
    /// - Given: An `AtomicDictionary` whose only value, when released, reads the same dictionary
    /// - When:
    ///    - `removeAll()` is called
    /// - Then:
    ///    - It returns, and the value's `deinit` saw an empty dictionary
    ///
    func testDictionaryRemoveAllReleasesValuesOutsideTheLock() {
        let dictionary = AtomicDictionary<Int, ReentrantValue>()
        let observedCount = AtomicValue<Int?>(initialValue: nil)
        dictionary.set(value: ReentrantValue { observedCount.set(dictionary.count) }, forKey: 1)

        // Checked before anything else touches the dictionary: after a deadlock its lock stays held.
        guard runsToCompletion({ dictionary.removeAll() }) else {
            return XCTFail("removeAll deadlocked")
        }
        XCTAssertEqual(observedCount.get(), 0)
    }

    /// Replacing a value releases the old one after unlocking
    ///
    /// - Given: An `AtomicDictionary` whose value, when released, removes another key of the same dictionary
    /// - When:
    ///    - The value is replaced with `set(value:forKey:)`
    /// - Then:
    ///    - It returns, and the old value's `deinit` removed the other key
    ///
    func testDictionarySetReleasesTheReplacedValueOutsideTheLock() {
        let dictionary = AtomicDictionary<Int, ReentrantValue>()
        dictionary.set(value: ReentrantValue { }, forKey: 2)
        dictionary.set(value: ReentrantValue { dictionary.removeValue(forKey: 2) }, forKey: 1)

        guard runsToCompletion({ dictionary.set(value: ReentrantValue { }, forKey: 1) }) else {
            return XCTFail("set(value:forKey:) deadlocked")
        }
        XCTAssertNil(dictionary.getValue(forKey: 2))
        XCTAssertNotNil(dictionary.getValue(forKey: 1))
    }

    /// `AtomicValue.set` releases the replaced value after unlocking
    ///
    /// - Given: An `AtomicValue` whose value, when released, reads the same `AtomicValue`
    /// - When:
    ///    - `set(_:)` replaces it
    /// - Then:
    ///    - It returns, and the old value's `deinit` saw the new value
    ///
    func testValueSetReleasesTheReplacedValueOutsideTheLock() {
        let atomic = AtomicValue<ReentrantValue?>(initialValue: nil)
        let observedNewValue = AtomicValue(initialValue: false)
        atomic.set(ReentrantValue { observedNewValue.set(atomic.get() != nil) })

        guard runsToCompletion({ atomic.set(ReentrantValue { }) }) else {
            return XCTFail("set(_:) deadlocked")
        }
        XCTAssertTrue(observedNewValue.get())
    }

    /// Runs `body` on its own thread and reports whether it finished within two seconds. A deadlocked
    /// thread is left blocked; the assertion reports it instead of hanging the test.
    private func runsToCompletion(_ body: @escaping @Sendable () -> Void) -> Bool {
        let finished = DispatchSemaphore(value: 0)
        Thread {
            body()
            finished.signal()
        }.start()
        return finished.wait(timeout: .now() + 2) == .success
    }
}

/// Runs `onDeinit` when it is released.
final class ReentrantValue: @unchecked Sendable {
    private let onDeinit: @Sendable () -> Void

    init(onDeinit: @escaping @Sendable () -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }
}
