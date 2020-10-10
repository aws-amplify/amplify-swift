//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class AtomicValue<Value> {
    let queue = DispatchQueue(label: "com.amazonaws.AtomicValue", target: DispatchQueue.global())

    var value: Value

    public init(initialValue: Value) {
        self.value = initialValue
    }

    public func get() -> Value {
        queue.sync { value }
    }

    public func set(_ newValue: Value) {
        queue.sync { value = newValue }
    }

    /// Sets AtomicValue to `newValue` and returns the old value
    public func getAndSet(_ newValue: Value) -> Value {
        return queue.sync {
            let oldValue = value
            value = newValue
            return oldValue
        }
    }

    /// Performs `block` with the current value, preventing other access until the block exits.
    public func atomicallyPerform(block: (Value) -> Void) {
        queue.sync {
            block(value)
        }
    }

    /// Performs `block` with an `inout` value, preventing other access until the block exits,
    /// and enabling the block to mutate the value
    public func with(block: (inout Value) -> Void) {
        queue.sync {
            block(&value)
        }
    }

}
