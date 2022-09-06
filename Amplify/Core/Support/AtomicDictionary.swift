//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

actor AtomicDictionary<Key: Hashable, Value> {
    private var value: [Key: Value]

    init(initialValue: [Key: Value] = [Key: Value]()) {
        self.value = initialValue
    }

    var count: Int {
        value.count
    }

    var keys: [Key] {
        Array(value.keys)
    }

    var values: [Value] {
        Array(value.values)
    }

    // MARK: - Functions

    func getValue(forKey key: Key) -> Value? {
        value[key]
    }

    func removeAll() {
        value = [:]
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        value.removeValue(forKey: key)
    }

    func set(value: Value, forKey key: Key) {
        self.value[key] = value
    }
}
