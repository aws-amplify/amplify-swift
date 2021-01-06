//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPIPlugin {

    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        let operation = AWSGraphQLOperation(request: request.toOperationRequest(operationType: .query),
                                            session: session,
                                            mapper: mapper,
                                            pluginConfig: pluginConfig,
                                            resultListener: listener)
        queue.addOperation(operation)
        return operation
    }

    func mutate<R: Decodable>(request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R> {
        let operation = AWSGraphQLOperation(request: request.toOperationRequest(operationType: .mutation),
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
            let operation = AWSGraphQLSubscriptionOperation(
                request: request.toOperationRequest(operationType: .subscription),
                pluginConfig: pluginConfig,
                subscriptionConnectionFactory: subscriptionConnectionFactory,
                authService: authService,
                apiAuthProviderFactory: authProviderFactory,
                inProcessListener: valueListener,
                resultListener: completionListener)
            queue.addOperation(operation)
            return operation
    }
}
