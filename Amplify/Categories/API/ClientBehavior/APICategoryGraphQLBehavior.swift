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
    /// - Parameter apiName: The name of graphQL API being invoked, as specified in `amplifyconfiguration.json`.
    ///   Specify this parameter when more than one API of this type is configured.
    /// - Parameter request: The GraphQL request containing document, variables, and responseType
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func query<R: Decodable>(apiName: String?,
                             request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL mutate operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter apiName: The name of graphQL API being invoked, as specified in `amplifyconfiguration.json`.
    ///   Specify this parameter when more than one API of this type is configured.
    /// - Parameter request: The GraphQL request containing document, variables, and responseType
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func mutate<R: Decodable>(apiName: String?,
                              request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL subscribe operation against a previously configured API. This operation
    /// will be asychronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - apiName: The name of graphQL API being invoked, as specified in `amplifyconfiguration.json`.
    ///   Specify this parameter when more than one API of this type is configured.
    ///   - request: The GraphQL request containing document, variables, and responseType
    ///   - listener: The event listener for the operation
    func subscribe<R: Decodable>(apiName: String?,
                                 request: GraphQLRequest<R>,
                                 listener: SubscriptionGraphQLOperation<R>.EventListener?) -> SubscriptionGraphQLOperation<R>
}
