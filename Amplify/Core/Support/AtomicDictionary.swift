//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class AtomicDictionary<Key: Hashable, Value> {

    /// <#Description#>
    let lock = NSLock()

    private var value: [Key: Value]

    /// <#Description#>
    /// - Parameter initialValue: <#initialValue description#>
    init(initialValue: [Key: Value] = [Key: Value]()) {
        self.value = initialValue
    }

    /// <#Description#>
    var count: Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value.count
    }

    /// <#Description#>
    var keys: [Key] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return Array(value.keys)
    }

    /// <#Description#>
    var values: [Value] {
        lock.lock()
        defer {
            lock.unlock()
        }
        return Array(value.values)
    }

    // MARK: - Functions

    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    func getValue(forKey key: Key) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value[key]
    }

    /// <#Description#>
    func removeAll() {
        lock.lock()
        defer {
            lock.unlock()
        }
        value = [:]
    }

    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value.removeValue(forKey: key)
    }

    /// <#Description#>
    /// - Parameters:
    ///   - value: <#value description#>
    ///   - key: <#key description#>
    func set(value: Value, forKey key: Key) {
        lock.lock()
        defer {
            lock.unlock()
        }
        self.value[key] = value
    }

}
