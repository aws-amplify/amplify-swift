//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AmplifyAPICategory: APICategoryGraphQLBehavior {

    // MARK: - Model-based GraphQL Operations

    public func query<M: Model>(from modelType: M.Type,
                                byId id: String,
                                listener: GraphQLOperation<M?>.ResultListener?) -> GraphQLOperation<M?> {
        plugin.query(from: modelType, byId: id, listener: listener)
    }

    public func query<M: Model>(from modelType: M.Type,
                                where predicate: QueryPredicate?,
                                listener: GraphQLOperation<[M]>.ResultListener?) -> GraphQLOperation<[M]> {
        plugin.query(from: modelType, where: predicate, listener: listener)
    }

    public func mutate<M: Model>(of model: M,
                                 type: GraphQLMutationType,
                                 listener: GraphQLOperation<M>.ResultListener?) -> GraphQLOperation<M> {
        plugin.mutate(of: model, type: type, listener: listener)
    }

    public func subscribe<M: Model>(from modelType: M.Type,
                                    type: GraphQLSubscriptionType,
                                    valueListener: GraphQLSubscriptionOperation<M>.InProcessListener?,
                                    completionListener: GraphQLSubscriptionOperation<M>.ResultListener?)
        -> GraphQLSubscriptionOperation<M> {
            plugin.subscribe(from: modelType,
                             type: type,
                             valueListener: valueListener,
                             completionListener: completionListener)
    }

    // MARK: - Request-based GraphQL operations

    public func query<R: Decodable>(request: GraphQLRequest<R>,
                                    listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        plugin.query(request: request, listener: listener)
    }

    public func mutate<R: Decodable>(request: GraphQLRequest<R>,
                                     listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        plugin.mutate(request: request, listener: listener)
    }

    public func subscribe<R>(request: GraphQLRequest<R>,
                             valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                             completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
        -> GraphQLSubscriptionOperation<R> {
            plugin.subscribe(request: request, valueListener: valueListener, completionListener: completionListener)
    }
}
