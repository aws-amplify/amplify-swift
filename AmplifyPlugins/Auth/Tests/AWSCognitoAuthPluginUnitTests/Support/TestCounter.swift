//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A thread-safe `Int` box for test state touched from `@Sendable` closures.
///
/// Exists because a plain `var` captured by a `@Sendable` closure is rejected in the Swift 6 language
/// mode, and neither available `AtomicValue` fits here: `AWSCognitoAuthPlugin` declares its own
/// internal `AtomicValue` that `@testable import` makes visible alongside Amplify's, and the collision
/// cannot be spelled away — `Amplify.AtomicValue` resolves against the `Amplify` *type* rather than the
/// module, because the two share a name.
///
/// The method names deliberately mirror `AtomicValue` so call sites read the same either way.
final class TestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int

    init(_ initialValue: Int = 0) {
        self.value = initialValue
    }

    func get() -> Int {
        lock.withLock { value }
    }

    func set(_ newValue: Int) {
        lock.withLock { value = newValue }
    }

    /// Sets `newValue` and returns what was there before, as one atomic step.
    func getAndSet(_ newValue: Int) -> Int {
        lock.withLock {
            let previous = value
            value = newValue
            return previous
        }
    }

    func increment() {
        lock.withLock { value += 1 }
    }
}
