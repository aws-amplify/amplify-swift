//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

extension APICategoryGraphQLBehavior {

    /// Default implementation of `query` to provide convenience for passing nil arguments.
    ///
    /// - Parameter request: GraphQL request
    /// - Returns: GraphQL operation
    public func query<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        query(request: request, listener: nil)
    }

    /// Default implementation of `mutate` to provide convenience for passing nil arguments.
    ///
    /// - Parameter request: GraphQL request
    /// - Returns: GraphQL operation
    public func mutate<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        mutate(request: request, listener: nil)
    }

    /// Default implementation of `subscribe` to provide convenience for passing nil arguments.
    ///
    /// - Parameter request: GraphQL request
    /// - Returns: GraphQL operation
    public func subscribe<R>(request: GraphQLRequest<R>) -> GraphQLSubscriptionOperation<R> {
        subscribe(request: request, valueListener: nil, completionListener: nil)
    }
}
