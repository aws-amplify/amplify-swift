//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category related to GraphQL operations
public protocol APICategoryGraphQLBehavior {


    func query<M: Model>(from modelType: M.Type,
                         byId id: String,
                         listener: GraphQLOperation<M?>.EventListener?) -> GraphQLOperation<M?>

    func query<M: Model>(from modelType: M.Type,
                         where predicate: QueryPredicate?,
                         listener: GraphQLOperation<[M]>.EventListener?) -> GraphQLOperation<[M]>

    func mutate<M: Model>(of model: M,
                          type: GraphQLMutationType,
                          listener: GraphQLOperation<M>.EventListener?) -> GraphQLOperation<M>

    func subscribe<M: Model>(from modelType: M.Type,
                             type: GraphQLSubscriptionType,
                             listener: GraphQLSubscriptionOperation<M>.EventListener?) -> GraphQLSubscriptionOperation<M>

    /// Perform a GraphQL query operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter request: The GraphQL request containing apiName, document, variables, and responseType
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL mutate operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter request: The GraphQL request containing apiName, document, variables, and responseType
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func mutate<R: Decodable>(request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.EventListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL subscribe operation against a previously configured API. This operation
    /// will be asychronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameter request: The GraphQL request containing apiName, document, variables, and responseType
    /// - Parameter listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func subscribe<R: Decodable>(request: GraphQLRequest<R>,
                                 listener: GraphQLSubscriptionOperation<R>.EventListener?)
        -> GraphQLSubscriptionOperation<R>
}



