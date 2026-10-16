//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// The engine's own `AtomicValue` releases what `set(_:)` replaces after unlocking, like Amplify's. The lock
/// is not reentrant, so a replaced value whose `deinit` uses the same `AtomicValue` must not run under it.
final class EngineAtomicValueTests: XCTestCase {

    /// `set(_:)` releases the replaced value after unlocking
    ///
    /// - Given: An engine `AtomicValue` whose value, when released, reads the same `AtomicValue`
    /// - When:
    ///    - `set(_:)` replaces it
    /// - Then:
    ///    - It returns, and the old value's `deinit` saw the new value
    ///
    func testSetReleasesTheReplacedValueOutsideTheLock() {
        // `nonisolated(unsafe)`: the engine's `AtomicValue` is not `Sendable`. Only the thread below and,
        // after it signals, the assertions use these.
        nonisolated(unsafe) let atomic = AtomicValue<ReleaseObserver?>(initialValue: nil)
        nonisolated(unsafe) var sawNewValue = false
        atomic.set(ReleaseObserver { sawNewValue = atomic.get() != nil })

        let finished = DispatchSemaphore(value: 0)
        Thread {
            atomic.set(ReleaseObserver { })
            finished.signal()
        }.start()

        // A deadlocked thread is left blocked; the assertion reports it instead of hanging the test.
        guard finished.wait(timeout: .now() + 2) == .success else {
            return XCTFail("set(_:) deadlocked")
        }
        XCTAssertTrue(sawNewValue)
    }
}

/// Runs `onDeinit` when it is released.
private final class ReleaseObserver {
    private let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }
}
