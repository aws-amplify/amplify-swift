//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AmplifyAPICategory: APICategoryGraphQLBehavior {

    // MARK: - Model-based GraphQL Operations

    public func query<M: Model>(_ modelType: M.Type,
                                byId id: String,
                                listener: GraphQLOperation<M?>.EventListener?) -> GraphQLOperation<M?> {
        plugin.query(modelType, byId: id, listener: listener)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                where predicate: QueryPredicate?,
                                listener: GraphQLOperation<[M]>.EventListener?) -> GraphQLOperation<[M]> {
        plugin.query(modelType, where: predicate, listener: listener)
    }

    public func mutate<M: Model>(_ model: M,
                                 where predicate: QueryPredicate? = nil,
                                 type: GraphQLMutationType,
                                 listener: GraphQLOperation<M>.EventListener?) -> GraphQLOperation<M> {
        plugin.mutate(model, where: predicate, type: type, listener: listener)
    }

    public func subscribe<M: Model>(to modelType: M.Type,
                                    type: GraphQLSubscriptionType,
                                    listener: GraphQLSubscriptionOperation<M>.EventListener?)
        -> GraphQLSubscriptionOperation<M> {
            plugin.subscribe(to: modelType, type: type, listener: listener)
    }

    // MARK: - Request-based GraphQL operations

    public func query<R: Decodable>(request: GraphQLRequest<R>,
                                    listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.query(request: request, listener: listener)
    }

    public func mutate<R: Decodable>(request: GraphQLRequest<R>,
                                     listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        plugin.mutate(request: request, listener: listener)
    }

    public func subscribe<R>(request: GraphQLRequest<R>,
                             listener: GraphQLSubscriptionOperation<R>.EventListener?)
        -> GraphQLSubscriptionOperation<R> {
            plugin.subscribe(request: request, listener: listener)
    }
}
