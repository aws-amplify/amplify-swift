//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

    // swiftlint:disable:next cyclomatic_complexity
    public func evaluate(target: Any) -> Bool {
        switch self {
        case .notEqual(let predicateValue):
            return !PersistableHelper.isEqual(target, predicateValue)
        case .equals(let predicateValue):
            return PersistableHelper.isEqual(target, predicateValue)
        case .lessOrEqual(let predicateValue):
            return PersistableHelper.isLessOrEqual(target, predicateValue)
        case .lessThan(let predicateValue):
            return PersistableHelper.isLessThan(target, predicateValue)
        case .greaterOrEqual(let predicateValue):
            return PersistableHelper.isGreaterOrEqual(target, predicateValue)
        case .greaterThan(let predicateValue):
            return PersistableHelper.isGreaterThan(target, predicateValue)
        case .contains(let predicateString):
            if let targetString = target as? String {
                return targetString.contains(predicateString)
            }
            return false
        case .between(let start, let end):
            return PersistableHelper.isBetween(start, end, target)
        case .beginsWith(let predicateValue):
            if let targetString = target as? String {
                return targetString.starts(with: predicateValue)
            }
        }
        return false
    }
}
