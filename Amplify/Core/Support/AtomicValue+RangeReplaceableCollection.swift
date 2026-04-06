//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension AtomicValue where Value: RangeReplaceableCollection {
    func append(_ newElement: Value.Element) {
        lock.execute {
            value.append(newElement)
        }
    }

    func append(contentsOf sequence: some Sequence<Value.Element>) {
        lock.execute {
            value.append(contentsOf: sequence)
        }
    }

    func removeFirst() -> Value.Element {
        lock.execute {
            value.removeFirst()
        }
    }

    subscript(_ key: Value.Index) -> Value.Element {
        lock.execute {
            value[key]
        }
    }
}
