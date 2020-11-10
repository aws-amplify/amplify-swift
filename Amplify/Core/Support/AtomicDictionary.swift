//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class AtomicDictionary<Key: Hashable, Value> {
    let lock = NSLock()

    private var value: [Key: Value]

    init(initialValue: [Key: Value] = [Key: Value]()) {
        self.value = initialValue
    }

    var count: Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value.count
    }

    var keys: [Key] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return Array(value.keys)
    }

    var values: [Value] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return Array(value.values)
    }

    // MARK: - Functions

    func getValue(forKey key: Key) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value[key]
    }

    func removeAll() {
        lock.lock()
        defer {
            lock.unlock()
        }
        value = [:]
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value.removeValue(forKey: key)
    }

    func set(value: Value, forKey key: Key) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.value[key] = value
    }

}
