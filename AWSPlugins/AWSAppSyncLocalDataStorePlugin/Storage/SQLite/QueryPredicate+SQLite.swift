//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension QueryPredicate {

    var operation: String {
        switch self {
        case .notEqual:
            return "<> ?"
        case .equals:
            return "= ?"
        case .lessOrEqual:
            return "<= ?"
        case .lessThan:
            return "< ?"
        case .greaterOrEqual:
            return ">= ?"
        case .greaterThan:
            return "> ?"
        case .contains:
            return "like ?"
        case .between:
            return "between ? and ?"
        case .beginsWith:
            return "like ?"
        }
    }

    func columnFor(field: String) -> String {
        switch self {
        case .contains, .beginsWith:
            return "upper(\(field.quoted()))"
        default:
            return field.quoted()
        }
    }

    var bindings: [Binding?] {
        switch self {
        case let .between(start, end):
            return [start.asBinding(), end.asBinding()]
        case .notEqual(let value), .equals(let value):
            return [value?.asBinding()]
        case .lessOrEqual(let value),
             .lessThan(let value),
             .greaterOrEqual(let value),
             .greaterThan(let value):
            return [value.asBinding()]
        case .contains(let value):
            return ["%\(value)%"]
        case .beginsWith(let value):
            return ["%\(value)"]
        }
    }
}
