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

// Convert QueryPredicate to GraphQLFilter JSON, and GraphQLFilter JSON to GraphQLFilter
public struct GraphQLFilterConverter {

    /// Serialize the translated GraphQL query variable object to JSON string.
    public static func toJSON(_ queryPredicate: QueryPredicate,
                              options: JSONSerialization.WritingOptions = []) throws -> String {
        let graphQLFilterData = try JSONSerialization.data(withJSONObject: queryPredicate.graphQLFilter,
                                                           options: options)

        guard let serializedString = String(data: graphQLFilterData, encoding: .utf8) else {
            preconditionFailure("""
                Could not initialize String from the GraphQL representation of QueryPredicate:
                \(String(describing: graphQLFilterData))
                """)
        }

        return serializedString
    }

    /// Deserialize the JSON string converted with `GraphQLFilterConverter.toJSON()` to `GraphQLFilter`
    public static func fromJSON(_ value: String) throws -> GraphQLFilter {
        guard let data = value.data(using: .utf8),
            let filter = try JSONSerialization.jsonObject(with: data) as? GraphQLFilter else {
            preconditionFailure("Could not serialize to GraphQLFilter from: \(self))")
        }

        return filter
    }
}

/// Extension to translate a `QueryPredicate` into a GraphQL query variables object
extension QueryPredicate {

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

extension QueryPredicateOperation: GraphQLFilterConvertible {
    var graphQLFilter: GraphQLFilter {
        return [field: [self.operator.graphQLOperator: self.operator.value]]
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
            if let predicate = predicates.first {
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
        switch self {
        case is Bool:
            return self
        case let double as Double:
            return Decimal(double)
        case is Int:
            return self
        case is String:
            return self
        case let temporalDate as Temporal.Date:
            return temporalDate.iso8601String
        case let temporalDateTime as Temporal.DateTime:
            return temporalDateTime.iso8601String
        case let temporalTime as Temporal.Time:
            return temporalTime.iso8601String
        default:
            preconditionFailure("""
            Value \(String(describing: self)) of type \(String(describing: type(of: self))) \
            is not a compatible type.
            """)
        }
    }
}
