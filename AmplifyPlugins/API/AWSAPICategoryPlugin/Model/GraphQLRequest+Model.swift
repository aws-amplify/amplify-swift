//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that provides an integration layer between `Model`, `GraphQLDocument` and `GraphQLRequest`.
/// This is particularly useful when using the GraphQL API to interact with static types that conform to
/// the `Model` protocol, also used by `DataStore`.
extension GraphQLRequest {

    /// Creates a `GraphQLRequest` that represents a mutation of a given `type` for a `model` instance.
    /// The request will be created with the correct document based on the `ModelSchema` and
    /// variables based on the model instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    ///   - type: the mutation type, either `.create`, `.update` or `.delete`
    /// - Returns: the `GraphQLRequest` ready to be used
    ///
    /// - seealso: `GraphQLMutation`, `GraphQLMutationType`
    public static func mutation<M: Model>(of model: M,
                                          type: GraphQLMutationType) -> GraphQLRequest<M> {
        let document = GraphQLMutation(of: model, type: type)
        return GraphQLRequest<M>(document: document.stringValue,
                                 variables: document.variables,
                                 responseType: M.self,
                                 decodePath: document.decodePath)
    }

    /// Creates a `GraphQLRequest` that represents a query that expects a single value as a result.
    /// The request will be created with the correct correct document based on the `ModelSchema` and
    /// variables based on given `id`.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - id: the model identifier
    /// - Returns: the `GraphQLRequest` ready to be used
    ///
    /// - seealso: `GraphQLQuery`, `GraphQLQueryType.get`
    public static func query<M: Model>(from modelType: M.Type,
                                       byId id: String) -> GraphQLRequest<M?> {
        let document = GraphQLQuery(from: modelType, type: .get)
        let variables: [String: Any] = [
            "id": id
        ]

        return GraphQLRequest<M?>(document: document.stringValue,
                                  variables: variables,
                                  responseType: M?.self,
                                  decodePath: document.decodePath)
    }

    /// Creates a `GraphQLRequest` that represents a query that expects multiple values as a result.
    /// The request will be created with the correct document based on the `ModelSchema` and
    /// variables based on the the predicate.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - predicate: an optional predicate containing the criteria for the query
    /// - Returns: the `GraphQLRequest` ready to be used
    ///
    /// - seealso: `GraphQLQuery`, `GraphQLQueryType.list`
    public static func query<M: Model>(from modelType: M.Type,
                                       where predicate: QueryPredicate? = nil) -> GraphQLRequest<[M]> {
        let document = GraphQLQuery(from: modelType, type: .list)
        var variables = [String: Any]()

        if let predicate = predicate {
            variables.updateValue(predicate.graphQLFilterVariables, forKey: "filter")
        }

        // Instead of being reactive to the limit and recursivly call the service, optimize by setting the limit
        // to the current AppSync's maximum limit and reduce the number of calls when exhausting `nextToken`.
        // https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_appsync
        variables.updateValue(1_000, forKey: "limit")

        // By constructing the query request in this way, we should pass in some options that check for "token"
        // and keep retrieving items until it's done and populate it back. like `exhaustList`
        return GraphQLRequest<[M]>(document: document.stringValue,
                                   variables: variables,
                                   responseType: [M].self,
                                   decodePath: document.decodePath)
    }

    /// Creates a `GraphQLRequest` that represents a subscription of a given `type` for a `model` type.
    /// The request will be created with the correct document based on the `ModelSchema`.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - type: the subscription type, either `.onCreate`, `.onUpdate` or `.onDelete`
    /// - Returns: the `GraphQLRequest` ready to be used
    ///
    /// - seealso: `GraphQLSubscription`, `GraphQLSubscriptionType`
    public static func subscription<M: Model>(of modelType: M.Type,
                                              type: GraphQLSubscriptionType) -> GraphQLRequest<M> {
        let document = GraphQLSubscription(of: modelType, type: type)
        return GraphQLRequest<M>(document: document.stringValue,
                                 responseType: modelType,
                                 decodePath: document.decodePath)
    }

}

extension QueryPredicate {
    var graphQLFilterVariables: [String: Any] {
        if let operation = self as? QueryPredicateOperation {
            return operation.graphQLFilterOperation
        } else if let group = self as? QueryPredicateGroup {
            return group.graphQLFilterGroup
        }
        fatalError("")
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
                fatalError("Missing predicate")
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
