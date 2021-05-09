//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public enum QueryOperator {

    /// <#Description#>
    case notEqual(_ value: Persistable?)

    /// <#Description#>
    case equals(_ value: Persistable?)

    /// <#Description#>
    case lessOrEqual(_ value: Persistable)

    /// <#Description#>
    case lessThan(_ value: Persistable)

    /// <#Description#>
    case greaterOrEqual(_ value: Persistable)

    /// <#Description#>
    case greaterThan(_ value: Persistable)

    /// <#Description#>
    case contains(_ value: String)

    /// <#Description#>
    case between(start: Persistable, end: Persistable)

    /// <#Description#>
    case beginsWith(_ value: String)

    /// <#Description#>
    /// - Parameter target: <#target description#>
    /// - Returns: <#description#>
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
