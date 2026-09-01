//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A thread-safe counter for asserting how many times a `@Sendable` mock closure ran.
///
/// Exists because a plain `var` captured by a `@Sendable` closure is rejected in the Swift 6 language
/// mode, and neither available `AtomicValue` fits here: `AWSCognitoAuthPlugin` declares its own
/// internal `AtomicValue` that `@testable import` makes visible alongside Amplify's, and the collision
/// cannot be spelled away — `Amplify.AtomicValue` resolves against the `Amplify` *type* rather than the
/// module, because the two share a name.
final class TestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Int

    init(_ initialValue: Int = 0) {
        self.value = initialValue
    }

    func increment() {
        lock.withLock { value += 1 }
    }

    var current: Int {
        lock.withLock { value }
    }
}
