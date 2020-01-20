//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class AtomicDictionary<Key: Hashable, Value> {
    let queue = DispatchQueue(label: "com.amazonaws.AtomicDictionary", target: DispatchQueue.global())

    private var value: [Key: Value]

    init(initialValue: [Key: Value] = [Key: Value]()) {
        self.value = initialValue
    }

    var count: Int {
        queue.sync {
            value.count
        }
    }

    var keys: [Key] {
        queue.sync {
            Array(value.keys)
        }
    }

    var values: [Value] {
        return queue.sync {
            Array(value.values)
        }
    }

    // MARK: - Functions

    func getValue(forKey key: Key) -> Value? {
        queue.sync {
            value[key]
        }
    }

    func removeAll() {
        queue.sync {
            value = [:]
        }
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        queue.sync {
            value.removeValue(forKey: key)
        }
    }

    func set(value: Value, forKey key: Key) {
        queue.sync {
            self.value[key] = value
        }
    }

}
