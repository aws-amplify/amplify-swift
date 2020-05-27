//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// MARK: - Protocol

/// Protocol that represents the integration between `GraphQLRequest` and `Model`.
///
/// The methods defined here are used to build a valid `GraphQLRequest` from types
/// conforming to `Model`.
protocol ModelGraphQLRequestFactory {

    // MARK: Query

    /// Creates a `GraphQLRequest` that represents a query that expects multiple values as a result.
    /// The request will be created with the correct document based on the `ModelSchema` and
    /// variables based on the the predicate.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - predicate: an optional predicate containing the criteria for the query
    /// - Returns: a valid `GraphQLRequest` instance
    ///
    /// - seealso: `GraphQLQuery`, `GraphQLQueryType.list`
    static func list<M: Model>(_ modelType: M.Type,
                               where predicate: QueryPredicate?) -> GraphQLRequest<[M]>

    /// Creates a `GraphQLRequest` that represents a query that expects a single value as a result.
    /// The request will be created with the correct correct document based on the `ModelSchema` and
    /// variables based on given `id`.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - id: the model identifier
    /// - Returns: a valid `GraphQLRequest` instance
    ///
    /// - seealso: `GraphQLQuery`, `GraphQLQueryType.get`
    static func get<M: Model>(_ modelType: M.Type, byId id: String) -> GraphQLRequest<M?>

    // MARK: Mutation

    /// Creates a `GraphQLRequest` that represents a mutation of a given `type` for a `model` instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    ///   - predicate: a predicate passed as the condition to apply the mutation
    ///   - type: the mutation type, either `.create`, `.update`, or `.delete`
    /// - Returns: a valid `GraphQLRequest` instance
    static func mutation<M: Model>(of model: M,
                                   where predicate: QueryPredicate?,
                                   type: GraphQLMutationType) -> GraphQLRequest<M>

    /// Creates a `GraphQLRequest` that represents a create mutation
    /// for a given `model` instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    /// - Returns: a valid `GraphQLRequest` instance
    /// - seealso: `GraphQLRequest.mutation(of:where:type:)`
    static func create<M: Model>(_ model: M) -> GraphQLRequest<M>

    /// Creates a `GraphQLRequest` that represents an update mutation
    /// for a given `model` instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    ///   - predicate: a predicate passed as the condition to apply the mutation
    /// - Returns: a valid `GraphQLRequest` instance
    /// - seealso: `GraphQLRequest.mutation(of:where:type:)`
    static func update<M: Model>(_ model: M,
                                 where predicate: QueryPredicate?) -> GraphQLRequest<M>

    /// Creates a `GraphQLRequest` that represents a delete mutation
    /// for a given `model` instance.
    ///
    /// - Parameters:
    ///   - model: the model instance populated with values
    ///   - predicate: a predicate passed as the condition to apply the mutation
    /// - Returns: a valid `GraphQLRequest` instance
    /// - seealso: `GraphQLRequest.mutation(of:where:type:)`
    static func delete<M: Model>(_ model: M,
                                 where predicate: QueryPredicate?) -> GraphQLRequest<M>

    // MARK: Subscription

    /// Creates a `GraphQLRequest` that represents a subscription of a given `type` for a `model` type.
    /// The request will be created with the correct document based on the `ModelSchema`.
    ///
    /// - Parameters:
    ///   - modelType: the metatype of the model
    ///   - type: the subscription type, either `.onCreate`, `.onUpdate` or `.onDelete`
    /// - Returns: a valid `GraphQLRequest` instance
    ///
    /// - seealso: `GraphQLSubscription`, `GraphQLSubscriptionType`
    static func subscription<M: Model>(of: M.Type,
                                       type: GraphQLSubscriptionType) -> GraphQLRequest<M>
}

// MARK: - Extension

/// Extension that provides an integration layer between `Model`,
/// `GraphQLDocument` and `GraphQLRequest` by conforming to `ModelGraphQLRequestFactory`.
///
/// This is particularly useful when using the GraphQL API to interact
/// with static types that conform to the `Model` protocol.
extension GraphQLRequest: ModelGraphQLRequestFactory {

    public static func create<M: Model>(_ model: M) -> GraphQLRequest<M> {
        return mutation(of: model, type: .create)
    }

    public static func update<M: Model>(_ model: M,
                                        where predicate: QueryPredicate? = nil) -> GraphQLRequest<M> {
        return mutation(of: model, where: predicate, type: .update)
    }

    public static func delete<M: Model>(_ model: M,
                                        where predicate: QueryPredicate? = nil) -> GraphQLRequest<M> {
        return mutation(of: model, where: predicate, type: .delete)
    }

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

    public static func get<M: Model>(_ modelType: M.Type,
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

    public static func list<M: Model>(_ modelType: M.Type,
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

    public static func subscription<M: Model>(of modelType: M.Type,
                                              type: GraphQLSubscriptionType) -> GraphQLRequest<M> {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelType: modelType, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: type))
        let document = documentBuilder.build()

        return GraphQLRequest<M>(document: document.stringValue,
                                 variables: document.variables,
                                 responseType: modelType,
                                 decodePath: document.name)
    }
}
