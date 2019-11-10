//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {

    /// Performs a GraphQL query
    ///
    /// - Parameter apiName: Name of the configured API
    /// - Parameter document: GraphQL query document
    /// - Parameter variables: specified for inputs specified in the `document`
    /// - Parameter responseType: The type to deserialize the response object to
    /// - Parameter listener: The closure to receive response updates.
    func query<R: Decodable>(apiName: String,
                             document: String,
                             variables: [String: Any]?,
                             responseType: R.Type,
                             listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            return graphql(apiName: apiName,
                           operationType: .query,
                           eventName: HubPayload.EventName.API.query,
                           document: document,
                           variables: variables,
                           responseType: responseType,
                           listener: listener)
    }

    /// Performs a GraphQL mutation
    ///
    /// - Parameter apiName: Name of the configured API
    /// - Parameter document: GraphQL query document
    /// - Parameter variables: specified for inputs specified in the `document`
    /// - Parameter responseType: The type to deserialize the response object to
    /// - Parameter listener: The closure to receive response updates.
    func mutate<R: Decodable>(apiName: String,
                              document: String,
                              variables: [String: Any]?,
                              responseType: R.Type,
                              listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            return graphql(apiName: apiName,
                           operationType: .mutation,
                           eventName: HubPayload.EventName.API.mutate,
                           document: document,
                           variables: variables,
                           responseType: responseType,
                           listener: listener)
    }

    func subscribe<R: Decodable>(apiName: String,
                                 document: String,
                                 variables: [String: Any]?,
                                 responseType: R.Type,
                                 listener: ((AsyncEvent<SubscriptionEvent<GraphQLResponse<R>>, Void, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, SubscriptionEvent<GraphQLResponse<R>>, Void, APIError> {

            let graphQLQueryRequest = GraphQLRequest(apiName: apiName,
                                                     operationType: .subscription,
                                                     document: document,
                                                     variables: variables,
                                                     options: GraphQLRequest.Options())

            let operation = AWSSubscriptionGraphQLOperation(request: graphQLQueryRequest,
                                                            responseType: responseType,
                                                            pluginConfig: pluginConfig,
                                                            subscriptionConnectionFactory: subscriptionConnectionFactory,
                                                            authService: authService,
                                                            listener: listener)
            queue.addOperation(operation)
            return operation
    }

    /// Used by `query` and `mutate` to consolidate creating a `GraphQLRequest` containing a snapshot of the request
    /// and `AWSGraphQlOperation` to perform the execution of the request
    private func graphql<R: Decodable>(apiName: String,
                                       operationType: GraphQLOperationType,
                                       eventName: String,
                                       document: String,
                                       variables: [String: Any]?,
                                       responseType: R.Type,
                                       listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError> {

            let graphQLQueryRequest = GraphQLRequest(apiName: apiName,
                                                     operationType: operationType,
                                                     document: document,
                                                     variables: variables,
                                                     options: GraphQLRequest.Options())

            let operation = AWSGraphQLOperation(request: graphQLQueryRequest,
                                                eventName: eventName,
                                                responseType: responseType,
                                                session: session,
                                                mapper: mapper,
                                                pluginConfig: pluginConfig,
                                                listener: listener)
            queue.addOperation(operation)
            return operation
    }
}
