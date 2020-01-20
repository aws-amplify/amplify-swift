//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AtomicValue where Value: RangeReplaceableCollection {
    public func append(_ newElement: Value.Element) {
        queue.sync {
            value.append(newElement)
        }
    }

    public func append<S>(contentsOf sequence: S) where S: Sequence, S.Element == Value.Element {
        queue.sync {
            value.append(contentsOf: sequence)
        }
    }

    public func removeFirst() -> Value.Element {
        queue.sync {
            value.removeFirst()
        }
    }

    public subscript(_ key: Value.Index) -> Value.Element {
        queue.sync {
            value[key]
        }
    }
}
