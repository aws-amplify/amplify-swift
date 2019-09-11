//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class AtomicValue<T> {
    private let queue = DispatchQueue(label: "com.amazonaws.AtomicValue")

    private var value: T

    init(initialValue: T) {
        self.value = initialValue
    }

    func get() -> T {
        return queue.sync { value }
    }

    func set(_ newValue: T) {
        queue.sync { value = newValue }
    }

    /// Sets AtomicValue to `newValue` and returns the old value
    func getAndSet(_ newValue: T) -> T {
        return queue.sync {
            let oldValue = value
            value = newValue
            return oldValue
        }
    }
}

// MARK: - Bool

extension AtomicValue where T == Bool {
    func toggle() -> T {
        return queue.sync {
            let oldValue = value
            value.toggle()
            return oldValue
        }
    }
}

// MARK: - Numeric

extension AtomicValue where T: Numeric {
    func increment(by amount: T = 1) -> T {
        return queue.sync {
            value += amount
            return value
        }
    }

    func decrement(by amount: T = 1) -> T {
        return queue.sync {
            value -= amount
            return value
        }
    }
}
