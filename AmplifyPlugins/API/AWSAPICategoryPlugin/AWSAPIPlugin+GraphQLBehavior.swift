//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPIPlugin {

    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .query)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func mutate<R: Decodable>(request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        let operationRequest = getOperationRequest(request: request,
                                                   operationType: .mutation)

        let operation = AWSGraphQLOperation(request: operationRequest,
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func subscribe<R>(
        request: GraphQLRequest<R>,
        valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
        completionListener: GraphQLSubscriptionOperation<R>.ResultListener?
    ) -> GraphQLSubscriptionOperation<R> {
            let operationRequest = getOperationRequest(request: request,
                                                       operationType: .subscription)

            let operation = AWSGraphQLSubscriptionOperation(
                request: operationRequest,
                pluginConfig: pluginConfig,
                subscriptionConnectionFactory: subscriptionConnectionFactory,
                authService: authService,
                apiAuthProviderFactory: authProviderFactory,
                inProcessListener: valueListener,
                resultListener: completionListener)
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
