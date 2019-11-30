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
        let document = GraphQLGetQuery(from: modelType, id: id)
        return GraphQLRequest<M?>(document: document.stringValue,
                                  variables: document.variables,
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
        let document = GraphQLListQuery(from: modelType, predicate: predicate)
        return GraphQLRequest<[M]>(document: document.stringValue,
                                   variables: document.variables,
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
