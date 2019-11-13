//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    func query<R: Decodable>(apiName: String? = nil,
                             request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(apiName: apiName,
                                                   request: request,
                                                   operationType: .query)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            listener: listener)
        queue.addOperation(operation)
        return operation
    }

    func mutate<R: Decodable>(apiName: String? = nil,
                              request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(apiName: apiName,
                                                   request: request,
                                                   operationType: .mutation)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            listener: listener)
        queue.addOperation(operation)
        return operation
    }

    func subscribe<R>(apiName: String? = nil,
                      request: GraphQLRequest<R>,
                      listener: SubscriptionGraphQLOperation<R>.EventListener?) -> SubscriptionGraphQLOperation<R> {

        let operationRequest = getOperationRequest(apiName: apiName,
                                                   request: request,
                                                   operationType: .subscription)

        let operation = AWSSubscriptionGraphQLOperation(request: operationRequest,
                                                        pluginConfig: pluginConfig,
                                                        subscriptionConnectionFactory: subscriptionConnectionFactory,
                                                        authService: authService,
                                                        listener: listener)
        queue.addOperation(operation)
        return operation
    }

    private func getOperationRequest<R: Decodable>(apiName: String?,
                                                   request: GraphQLRequest<R>,
                                                   operationType: GraphQLOperationType) -> GraphQLOperationRequest<R> {

        let operationRequest = GraphQLOperationRequest(apiName: apiName,
                                                       operationType: operationType,
                                                       document: request.document,
                                                       variables: request.variables,
                                                       responseType: request.responseType,
                                                       options: GraphQLOperationRequest.Options())
        return operationRequest
    }
}
