//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class SynchronizedDictionary<Key: Hashable, Value> {
    private let concurrencyQueue = DispatchQueue(label: "com.amazonaws.SynchronizedDictionary",
                                                 qos: .default,
                                                 attributes: .concurrent)

    private var elements = [Key: Value]()

    // MARK: - Properties

    var count: Int {
        return concurrencyQueue.sync {
            elements.count
        }
    }

    var keys: [Key] {
        return concurrencyQueue.sync {
            Array(elements.keys)
        }
    }

    var values: [Value] {
        return concurrencyQueue.sync {
            Array(elements.values)
        }
    }

    // MARK: - Functions

    func getValue(forKey key: Key) -> Value? {
        return concurrencyQueue.sync {
            elements[key]
        }
    }

    func removeAll() {
        concurrencyQueue.async(flags: .barrier) {
            self.elements = [:]
        }
    }

    func removeValue(forKey key: Key) {
        concurrencyQueue.async(flags: .barrier) {
            self.elements.removeValue(forKey: key)
        }
    }

    func set(value: Value, forKey key: Key) {
        concurrencyQueue.async(flags: .barrier) {
            self.elements[key] = value
        }
    }

}
