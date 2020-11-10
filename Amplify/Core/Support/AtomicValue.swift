//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class AtomicValue<Value> {
    let lock = NSLock()

    var value: Value

    public init(initialValue: Value) {
        self.value = initialValue
    }

    public func get() -> Value {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value
    }

    public func set(_ newValue: Value) {
        lock.lock()
        defer {
            lock.unlock()
        }
        value = newValue
    }

    /// Sets AtomicValue to `newValue` and returns the old value
    public func getAndSet(_ newValue: Value) -> Value {
        lock.lock()
        defer {
            lock.unlock()
        }
        let oldValue = value
        value = newValue
        return oldValue
    }

    /// Performs `block` with the current value, preventing other access until the block exits.
    public func atomicallyPerform(block: (Value) -> Void) {
        lock.lock()
        defer {
            lock.unlock()
        }
        block(value)
    }

    /// Performs `block` with an `inout` value, preventing other access until the block exits,
    /// and enabling the block to mutate the value
    public func with(block: (inout Value) -> Void) {
        lock.lock()
        defer {
            lock.unlock()
        }
        block(&value)
    }

}
