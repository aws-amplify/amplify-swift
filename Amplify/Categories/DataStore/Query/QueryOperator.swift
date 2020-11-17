//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum QueryOperator {
    case notEqual(_ value: Persistable?)
    case equals(_ value: Persistable?)
    case lessOrEqual(_ value: Persistable)
    case lessThan(_ value: Persistable)
    case greaterOrEqual(_ value: Persistable)
    case greaterThan(_ value: Persistable)
    case contains(_ value: String)
    case between(start: Persistable, end: Persistable)
    case beginsWith(_ value: String)

    public func evaluate(target: Any) -> Bool {
        switch self {
        case .notEqual(let value):
            return !PersistableHelper.isEqual(value, target)
        case .equals(let value):
            return PersistableHelper.isEqual(value, target)
        case .lessOrEqual(let value):
            return PersistableHelper.isLessOrEqual(value, target)
        case .lessThan(let value):
            return PersistableHelper.isLessThan(value, target)
        case .greaterOrEqual(let value):
            return PersistableHelper.isGreaterOrEqual(value, target)
        case .greaterThan(let value):
            return PersistableHelper.isGreaterThan(value, target)
        case .contains(let value):
            if let targetString = target as? String {
                return targetString.contains(value)
            }
            return false
        case .between(let start, let end):
            return PersistableHelper.isBetween(start, end, target)
        case .beginsWith(let value):
            if let targetString = target as? String {
                return targetString.starts(with: value)
            }
        }
        return false
    }
}
