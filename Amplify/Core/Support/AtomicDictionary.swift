//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `@unchecked Sendable` because `value` is mutable but every access below is serialized by
///   `lock`. `Key`/`Value` are deliberately unconstrained so existing callers keep working; as
///   before, whether the *elements* are safe to use across domains remains the caller's concern.
public final class AtomicDictionary<Key: Hashable, Value>: @unchecked Sendable {
    // Concrete `NSLock` rather than the `any NSLocking` existential, which is not `Sendable`.
    private let lock: NSLock
    private var value: [Key: Value]

    public init(initialValue: [Key: Value] = [Key: Value]()) {
        self.lock = NSLock()
        self.value = initialValue
    }

    public var count: Int {
        lock.execute { value.count }
    }

    public var keys: [Key] {
        lock.execute { Array(value.keys) }
    }

    public var values: [Value] {
        lock.execute { Array(value.values) }
    }

    // MARK: - Functions

    public func getValue(forKey key: Key) -> Value? {
        lock.execute { value[key] }
    }

    // The mutators below hand what they replace back out of `lock.execute`, so it is released after the lock
    // is dropped. A released value can run a `deinit` that uses this dictionary again (a Hub listener's
    // captured object removing that listener, for example), and the lock is not reentrant.

    public func removeAll() {
        let removed = lock.execute {
            let removed = value
            value = [:]
            return removed
        }
        _ = removed
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        return lock.execute { value.removeValue(forKey: key) }
    }

    public func set(value: Value, forKey key: Key) {
        let replaced = lock.execute { self.value.updateValue(value, forKey: key) }
        _ = replaced
    }

    public subscript(key: Key) -> Value? {
        get {
            getValue(forKey: key)
        }
        set {
            if let newValue {
                set(value: newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }
}

extension AtomicDictionary: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (Key, Value)...) {
        let dictionary: [Key: Value] = .init(uniqueKeysWithValues: elements)
        self.init(initialValue: dictionary)
    }
}

extension AtomicDictionary: Sequence {
    typealias Iterator = DictionaryIterator

    public func makeIterator() -> DictionaryIterator<Key, Value> {
        lock.execute {
            value.makeIterator()
        }
    }
}
