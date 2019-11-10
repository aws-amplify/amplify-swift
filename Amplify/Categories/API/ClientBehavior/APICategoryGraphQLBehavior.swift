//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category related to GraphQL operations
public protocol APICategoryGraphQLBehavior {

    /// Perform a GraphQL query operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter apiName: The name of API being invoked, as specified in `amplifyconfiguration.json`
    /// - Parameter document: GraphQL query document string
    /// - Parameter variables: GraphQL variables to replace dynamic values in the GraphQL query document
    /// - Parameter responseType: The type to deserialize response data to
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func query<R: Decodable>(apiName: String,
                             document: String,
                             variables: [String: Any]?,
                             responseType: R.Type,
                             listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError>

    /// Perform a GraphQL mutate operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter apiName: The name of API being invoked, as specified in `amplifyconfiguration.json`
    /// - Parameter document: GraphQL query document string
    /// - Parameter variables: GraphQL variables to replace dynamic values in the GraphQL query document
    /// - Parameter responseType: The type to deserialize response data to
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func mutate<R: Decodable>(apiName: String,
                              document: String,
                              variables: [String: Any]?,
                              responseType: R.Type,
                              listener: ((AsyncEvent<Void, GraphQLResponse<R>, APIError>) -> Void)?) ->
        AmplifyOperation<GraphQLRequest, Void, GraphQLResponse<R>, APIError>

    func subscribe<R: Decodable>(apiName: String,
                                 document: String,
                                 variables: [String: Any]?,
                                 responseType: R.Type,
                                 listener: ((AsyncEvent<SubscriptionEvent<GraphQLResponse<R>>, Void, APIError>) -> Void)?) ->
    AmplifyOperation<GraphQLRequest, SubscriptionEvent<GraphQLResponse<R>>, Void, APIError>
}
