//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Behavior of the API category related to GraphQL operations
public protocol APICategoryGraphQLBehavior: class {

    // MARK: - Model-based GraphQL Operations

    /// Perform a GraphQL query for a single `Model` item. This operation will be asychronous, with the callback
    /// accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - modelType: The type for the item returned
    ///   - id: Unique identifier of the item to retrieve
    ///   - listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued.
    func query<M: Model>(from modelType: M.Type,
                         byId id: String,
                         listener: GraphQLOperation<M?>.ResultListener?) -> GraphQLOperation<M?>

    /// Performs a GraphQL query for a list of `Model` items which satisfies the `predicate`. This operation will be
    /// asychronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - modelType: The type for the items returned
    ///   - predicate: The filter for which items to query
    ///   - listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued.
    func query<M: Model>(from modelType: M.Type,
                         where predicate: QueryPredicate?,
                         listener: GraphQLOperation<[M]>.ResultListener?) -> GraphQLOperation<[M]>

    /// Performs a GraphQL mutate for the `Model` item. This operation will be asynchronous, with the callback
    /// accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - model: The instance of the `Model`.
    ///   - type: The type of mutation to apply on the instance of `Model`.
    ///   - listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued.
    func mutate<M: Model>(of model: M,
                          type: GraphQLMutationType,
                          listener: GraphQLOperation<M>.ResultListener?) -> GraphQLOperation<M>

    /// Performs a GraphQL subscribe operation for `Model` items.
    ///
    /// - Parameters:
    ///   - modelType: The type of items to be subscribed to
    ///   - type: The type of subscription for the items
    ///   - valueListener: Invoked when the GraphQL subscription receives a new value from the service
    ///   - completionListener: Invoked when the subscription has terminated
    /// - Returns: The AmplifyInProcessReportingOperation being enqueued.
    func subscribe<M: Model>(from modelType: M.Type,
                             type: GraphQLSubscriptionType,
                             valueListener: GraphQLSubscriptionOperation<M>.InProcessListener?,
                             completionListener: GraphQLSubscriptionOperation<M>.ResultListener?)
        -> GraphQLSubscriptionOperation<M>

    // MARK: - Request-based GraphQL Operations

    /// Perform a GraphQL query operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    ///   - listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func query<R: Decodable>(request: GraphQLRequest<R>,
                             listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL mutate operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    ///   - listener: The event listener for the operation
    /// - Returns: The AmplifyOperation being enqueued
    func mutate<R: Decodable>(request: GraphQLRequest<R>,
                              listener: GraphQLOperation<R>.ResultListener?) -> GraphQLOperation<R>

    /// Perform a GraphQL subscribe operation against a previously configured API. This operation
    /// will be asychronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    ///   - valueListener: Invoked when the GraphQL subscription receives a new value from the service
    ///   - completionListener: Invoked when the subscription has terminated
    /// - Returns: The AmplifyInProcessReportingOperation being enqueued
    func subscribe<R: Decodable>(request: GraphQLRequest<R>,
                                 valueListener: GraphQLSubscriptionOperation<R>.InProcessListener?,
                                 completionListener: GraphQLSubscriptionOperation<R>.ResultListener?)
        -> GraphQLSubscriptionOperation<R>
}
