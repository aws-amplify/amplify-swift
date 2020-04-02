//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Extension that provides an integration layer between `Model`, `GraphQLDocument` and `GraphQLRequest`.
/// This is particularly useful when using the GraphQL API to interact with static types that conform to
/// the `Model` protocol.
extension GraphQLRequest {

    /// Creates a `GraphQLRequest` that represents a mutation of a given `type` for a `model` instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    ///   - predicate: a predicate passed as the condition to apply the mutation
    ///   - type: the mutation type, either `.create`, `.update`, or `.delete`
    /// - Returns: the `GraphQLRequest` ready to be used
    public static func mutation<M: Model>(of model: M,
                                          where predicate: QueryPredicate? = nil,
                                          type: GraphQLMutationType) -> GraphQLRequest<M> {
        let modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: type))

        switch type {
        case .create:
            documentBuilder.add(decorator: ModelDecorator(model: model))
        case .delete:
            documentBuilder.add(decorator: ModelIdDecorator(id: model.id))
            if let predicate = predicate {
                documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
            }
        case .update:
            documentBuilder.add(decorator: ModelDecorator(model: model))
            if let predicate = predicate {
                documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
            }
        }

        let document = documentBuilder.build()
        return GraphQLRequest<M>(document: document.stringValue,
                                 variables: document.variables,
                                 responseType: M.self,
                                 decodePath: document.name)
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
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: id))
        let document = documentBuilder.build()

        return GraphQLRequest<M?>(document: document.stringValue,
                                  variables: document.variables,
                                  responseType: M?.self,
                                  decodePath: document.name)
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
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))

        if let predicate = predicate {
            documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        }

        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()

        return GraphQLRequest<[M]>(document: document.stringValue,
                                   variables: document.variables,
                                   responseType: [M].self,
                                   decodePath: document.name + ".items")
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
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: type))
        let document = documentBuilder.build()

        return GraphQLRequest<M>(document: document.stringValue,
                                 responseType: modelType,
                                 decodePath: document.name)
    }
}
