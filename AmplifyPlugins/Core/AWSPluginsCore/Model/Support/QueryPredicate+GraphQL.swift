//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias GraphQLFilter = [String: Any]

protocol GraphQLFilterConvertible {
    var graphQLFilter: GraphQLFilter { get }
}

/// Extension to translate a `QueryPredicate` into a GraphQL query variables object
extension QueryPredicate {

    /// Serialize the translated GraphQL query variable object to JSON string.
    /// See `String` extension `toGraphQLFilter()` method to deserialize
    public func toGraphQLFilterJSON(options: JSONSerialization.WritingOptions = []) throws -> String {
        let graphQLFilterData = try JSONSerialization.data(withJSONObject: graphQLFilter,
                                                           options: options)

        guard let serializedString = String(data: graphQLFilterData, encoding: .utf8) else {
            preconditionFailure("""
                Could not initialize String from the GraphQL representation of QueryPredicate:
                \(String(describing: graphQLFilterData))
                """)
        }

        return serializedString
    }

    public var graphQLFilter: GraphQLFilter {
        if let operation = self as? QueryPredicateOperation {
            return operation.graphQLFilter
        } else if let group = self as? QueryPredicateGroup {
            return group.graphQLFilter
        }

        preconditionFailure(
            "Could not find QueryPredicateOperation or QueryPredicateGroup for \(String(describing: self))")
    }
}

extension String {

    /// Deserialize the JSON string converted with `QueryPredicate.toGraphQLFilterJSON()` to `GraphQLFilter`
    public func toGraphQLFilter() throws -> GraphQLFilter {
        let data = Data(utf8)
        guard let queryPredicateJson = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            preconditionFailure("Could not initialize JSON from queryPredicate String: \(self))")
        }
        return queryPredicateJson
    }
}

extension QueryPredicateOperation: GraphQLFilterConvertible {
    var graphQLFilter: GraphQLFilter {
        return [self.field: [self.operator.graphQLOperator: self.operator.value]]
    }
}

extension QueryPredicateGroup: GraphQLFilterConvertible {
    var graphQLFilter: GraphQLFilter {
        let logicalOperator = type.rawValue
        switch type {
        case .and, .or:
            var graphQLPredicateOperation = [logicalOperator: [Any]()]
            predicates.forEach { predicate in
                graphQLPredicateOperation[logicalOperator]?.append(predicate.graphQLFilter)
            }
            return graphQLPredicateOperation
        case .not:
            if let predicate = self.predicates.first {
                return [logicalOperator: predicate.graphQLFilter]
            } else {
                preconditionFailure("Missing predicate for \(String(describing: self)) with type: \(type)")
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

    var value: Any? {
        switch self {
        case .notEqual(let value),
             .equals(let value):
            if let value = value {
                return value.graphQLValue()
            }

            return nil
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
    internal func graphQLValue() -> Any {
        let value = self

        if let value = value as? Bool {
            return value
        }

        if let value = value as? Date {
            return value.iso8601String
        }

        if let value = value as? Double {
            return Decimal(value)
        }

        if let value = value as? Int {
            return value
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
