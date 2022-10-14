//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class AtomicDictionary<Key: Hashable, Value> {
    private let lock: NSLocking
    private var value: [Key: Value]

    init(initialValue: [Key: Value] = [Key: Value]()) {
        self.lock = NSLock()
        self.value = initialValue
    }

    var count: Int {
        lock.execute { value.count }
    }

    var keys: [Key] {
        lock.execute { Array(value.keys) }
    }

    var values: [Value] {
        lock.execute { Array(value.values) }
    }

    // MARK: - Functions

    func getValue(forKey key: Key) -> Value? {
        lock.execute { value[key] }
    }

    func removeAll() {
        lock.execute { value = [:] }
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        return lock.execute { value.removeValue(forKey: key) }
    }

    func set(value: Value, forKey key: Key) {
        lock.execute { self.value[key] = value }
    }
}
