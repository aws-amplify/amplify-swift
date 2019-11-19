//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    // MARK: - GraphQL model based APIs

    func query<M: Model>(from modelType: M.Type,
                         byId id: String,
                         listener: GraphQLOperation<M?>.EventListener?) -> GraphQLOperation<M?> {
        let request = GraphQLRequest<M>.query(from: modelType, byId: id)
        return query(request: request, listener: listener)
    }

    func query<M: Model>(from modelType: M.Type,
                         where predicate: QueryPredicate?,
                         listener: GraphQLOperation<[M]>.EventListener?) -> GraphQLOperation<[M]> {
        let request = GraphQLRequest<[M]>.query(from: modelType, where: predicate)
        return query(request: request, listener: listener)
    }

    func mutate<M: Model>(of model: M,
                          type: GraphQLMutationType,
                          listener: GraphQLOperation<M>.EventListener?) -> GraphQLOperation<M> {
        let request = GraphQLRequest<M>.mutation(of: model, type: type)
        return mutate(request: request, listener: listener)
    }

    func subscribe<M: Model>(from modelType: M.Type,
                             type: GraphQLSubscriptionType,
                             listener: GraphQLSubscriptionOperation<M>.EventListener?) -> GraphQLSubscriptionOperation<M> {
        let request = GraphQLRequest<M>.subscription(of: modelType, type: type)
        return subscribe(request: request, listener: listener)
    }

    // MARK: GraphQL document based APIs

    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .query)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            listener: listener)
        queue.addOperation(operation)
        return operation
    }

    func mutate<R: Decodable>(request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .mutation)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            listener: listener)
        queue.addOperation(operation)
        return operation
    }

    func subscribe<R>(request: GraphQLRequest<R>,
                      listener: GraphQLSubscriptionOperation<R>.EventListener?) ->
        GraphQLSubscriptionOperation<R> {

            let operationRequest = getOperationRequest(request: request,
                                                       operationType: .subscription)

            let operation = AWSGraphQLSubscriptionOperation(request: operationRequest,
                                                            pluginConfig: pluginConfig,
                                                            subscriptionConnectionFactory: subscriptionConnectionFactory,
                                                            authService: authService,
                                                            listener: listener)
            queue.addOperation(operation)
            return operation
    }

    private func getOperationRequest<R: Decodable>(request: GraphQLRequest<R>,
                                                   operationType: GraphQLOperationType) -> GraphQLOperationRequest<R> {

        let operationRequest = GraphQLOperationRequest(apiName: request.apiName,
                                                       operationType: operationType,
                                                       document: request.document,
                                                       variables: request.variables,
                                                       responseType: request.responseType,
                                                       decodePath: request.decodePath,
                                                       options: GraphQLOperationRequest.Options())
        return operationRequest
    }
}
