//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A thread-safe box for test state touched from `@Sendable` closures.
///
/// Exists for the same reason as ``TestCounter``: a plain `var` captured by a `@Sendable` closure is
/// rejected in the Swift 6 language mode, and Amplify's `AtomicValue` cannot be referenced from these
/// tests. `AWSCognitoAuthPlugin` declares its own internal `AtomicValue`, which `@testable import`
/// makes visible alongside Amplify's, and the collision cannot be spelled away — `Amplify.AtomicValue`
/// resolves against the `Amplify` *type* rather than the module, because the two share a name.
///
/// The method names mirror `AtomicValue` so call sites read the same either way.
final class TestBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ initialValue: Value) {
        self.value = initialValue
    }

    func get() -> Value {
        lock.withLock { value }
    }

    func set(_ newValue: Value) {
        lock.withLock { value = newValue }
    }

    /// Mutates the boxed value in place under the lock.
    func with(_ body: (inout Value) -> Void) {
        lock.withLock { body(&value) }
    }
}
