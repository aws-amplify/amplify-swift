//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension QueryOperator {

    var sqlOperation: String {
        switch self {
        case .notEqual(let value):
            return value == nil ? "is not null" : "<> ?"
        case .equals(let value):
            return value == nil ? "is null" : "= ?"
        case .lessOrEqual:
            return "<= ?"
        case .lessThan:
            return "< ?"
        case .greaterOrEqual:
            return ">= ?"
        case .greaterThan:
            return "> ?"
        case .between:
            return "between ? and ?"
        case .beginsWith, .contains:
            return "like ?"
        case .notContains:
            return "not like ?"
        }
    }

    var bindings: [Binding?] {
        switch self {
        case let .between(start, end):
            return [start.asBinding(), end.asBinding()]
        case .notEqual(let value), .equals(let value):
            return value == nil ? [] : [value?.asBinding()]
        case .lessOrEqual(let value),
             .lessThan(let value),
             .greaterOrEqual(let value),
             .greaterThan(let value):
            return [value.asBinding()]
        case .contains(let value):
            return ["%\(value)%"]
        case .beginsWith(let value):
            return ["\(value)%"]
        case .notContains(let value):
            return ["%\(value)%"]
        }
    }
}

extension QueryPredicate {
    var isAll: Bool {
        if let allPredicate = self as? QueryPredicateConstant, allPredicate == .all {
            return true
        } else {
            return false
        }
    }
}
