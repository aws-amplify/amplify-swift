//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPIPlugin {

    func query<M: Model>(from modelType: M.Type,
                         byId id: String,
                         listener: GraphQLOperation<M?>.ResultListener?) -> GraphQLOperation<M?> {
        let request = GraphQLRequest<M>.query(from: modelType, byId: id)
        return query(request: request, listener: listener)
    }

    func query<M: Model>(from modelType: M.Type,
                         where predicate: QueryPredicate?,
                         listener: GraphQLOperation<[M]>.ResultListener?) -> GraphQLOperation<[M]> {
        let request = GraphQLRequest<[M]>.query(from: modelType, where: predicate)
        return query(request: request, listener: listener)
    }

    func mutate<M: Model>(of model: M,
                          type: GraphQLMutationType,
                          listener: GraphQLOperation<M>.ResultListener?) -> GraphQLOperation<M> {
        let request = GraphQLRequest<M>.mutation(of: model, type: type)
        return mutate(request: request, listener: listener)
    }

    func mutate(ofAnyModel anyModel: AnyModel,
                type: GraphQLMutationType,
                listener: GraphQLOperation<AnyModel>.ResultListener?) -> GraphQLOperation<AnyModel> {
        let request = GraphQLRequest<AnyModel>.mutation(of: anyModel, type: type)
        return mutate(request: request, listener: listener)
    }

    func subscribe<M: Model>(
        from modelType: M.Type,
        type: GraphQLSubscriptionType,
        valueListener: GraphQLSubscriptionOperation<M>.InProcessListener?,
        completionListener: GraphQLSubscriptionOperation<M>.ResultListener?
    ) -> GraphQLSubscriptionOperation<M> {
        let request = GraphQLRequest<M>.subscription(of: modelType, type: type)
        return subscribe(request: request, valueListener: valueListener, completionListener: completionListener)
    }
}
