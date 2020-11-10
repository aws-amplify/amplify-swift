//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AtomicValue where Value: Numeric {
    /// Increments the current value by `amount` and returns the incremented value
    public func increment(by amount: Value = 1) -> Value {
        lock.lock()
        defer {
            lock.unlock()
        }
        value += amount
        return value
    }

    /// Decrements the current value by `amount` and returns the decremented value
    public func decrement(by amount: Value = 1) -> Value {
        lock.lock()
        defer {
            lock.unlock()
        }
        value -= amount
        return value
    }
}
