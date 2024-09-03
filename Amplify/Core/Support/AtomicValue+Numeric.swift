//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension AtomicValue where Value: Numeric {
    /// Increments the current value by `amount` and returns the incremented value
    func increment(by amount: Value = 1) -> Value {
        lock.execute {
            value += amount
            return value
        }
    }

    /// Decrements the current value by `amount` and returns the decremented value
    func decrement(by amount: Value = 1) -> Value {
        lock.execute {
            value -= amount
            return value
        }
    }
}
