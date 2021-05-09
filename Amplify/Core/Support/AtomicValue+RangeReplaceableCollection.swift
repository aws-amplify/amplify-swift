//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AtomicValue where Value: RangeReplaceableCollection {

    /// <#Description#>
    /// - Parameter newElement: <#newElement description#>
    public func append(_ newElement: Value.Element) {
        lock.lock()
        defer {
            lock.unlock()
        }
        value.append(newElement)
    }

    /// <#Description#>
    /// - Parameter sequence: <#sequence description#>
    public func append<S>(contentsOf sequence: S) where S: Sequence, S.Element == Value.Element {
        lock.lock()
        defer {
            lock.unlock()
        }
        value.append(contentsOf: sequence)
    }

    /// <#Description#>
    /// - Returns: <#description#>
    public func removeFirst() -> Value.Element {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value.removeFirst()
    }

    /// <#Description#>
    public subscript(_ key: Value.Index) -> Value.Element {
        lock.lock()
        defer {
            lock.unlock()
        }
        return value[key]
    }
}
