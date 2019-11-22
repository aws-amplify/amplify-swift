//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

typealias GraphQLInput = [String: Any?]

/// Extension that adds GraphQL specific utilities to concret types of `Model`.
extension Model {

    /// Get the `Model` values as a `Dictionary` of `String` to `Any?` that can be
    /// used as the `input` of GraphQL related operations.
    var graphQLInput: GraphQLInput {
        var input: GraphQLInput = [:]
        schema.fields.forEach {
            let field = $0.value
            let name = field.graphQLName
            let value = self[field.name]

            switch field.typeDefinition {
            case .date, .dateTime:
                if let date = value as? Date {
                    input[name] = date.iso8601
                } else {
                    input[name] = value
                }
            case .collection(let of):
                // TODO handle relationships (connected properties)
                break
            default:
                input[name] = value
            }
        }
        return input
    }
}
/*
extension QueryPredicate {
    var graphQLFilterVariables: [String: Any] {
        if let operation = self as? QueryPredicateOperation {
            return operation.graphQLFilterOperation
        } else if let group = self as? QueryPredicateGroup {
            return group.graphQLFilterGroup
        }

        // TODO: Should never happen, probably throw preconditionFailure or fatalError
        return [String: Any]()
    }
}

extension QueryPredicateOperation {
    var graphQLFilterOperation: [String: Any] {
        return [self.field: [self.operator.graphQLOperator: self.operator.value]]
    }
}

extension QueryPredicateGroup {
    var graphQLFilterGroup: [String: Any] {
        switch type {
        case .and, .or:
            var graphQLPredicateOperation = [self.type.rawValue: [Any]()]
            predicates.forEach { predicate in
                graphQLPredicateOperation[self.type.rawValue]?.append(predicate.graphQLFilterVariables)
            }
            return graphQLPredicateOperation
        case .not:
            if let predicate = self.predicates.first {
                return [self.type.rawValue: predicate.graphQLFilterVariables]
            } else {
                // TODO: Should never happen, probably throw preconditionFailure or fatalError
                return [self.type.rawValue: ""]
            }
        }
    }
}
extension QueryOperator {
    var graphQLOperator: String {
        switch self {
        case .notEqual:
            return "ne"
        case .equals:
            return "eq"
        case .lessOrEqual:
            return "le"
        case .lessThan:
            return "lt"
        case .greaterOrEqual:
            return "ge"
        case .greaterThan:
            return "gt"
        case .contains:
            return "contains"
        case .between:
            return "between"
        case .beginsWith:
            return "beginsWith"
        }
    }

    var value: Any {
        switch self {
        case .notEqual(let value),
             .equals(let value):
            if let value = value {
                return value.graphQLValue()
            }
            // shouldn't you return nil in case the value is nil?
            return ""
        case .lessOrEqual(let value),
             .lessThan(let value),
             .greaterOrEqual(let value),
             .greaterThan(let value):
            return value.graphQLValue()
        case .contains(let value):
            return value
        case .between(let start, let end):
            return [start.graphQLValue(), end.graphQLValue()]
        case .beginsWith(let value):
            return value
        }
    }
}

extension Persistable {
    // TODO: is this correct? by looking at the generated GraphQL types, it seems like the operators can handle Boolean,
    // Float, etc.
    internal func graphQLValue() -> String {
        let value = self

        if let value = value as? Bool {
            return String(value)
        }

        if let value = value as? Date {
            return value.iso8601
        }

        if let value = value as? Double {
            return String(value)
        }

        if let value = value as? Int {
            return String(value)
        }

        if let value = value as? String {
            return value
        }

        preconditionFailure("""
        Value \(String(describing: value)) of type \(String(describing: type(of: value)))
        is not a compatible type.
        """)
    }
}
*/
