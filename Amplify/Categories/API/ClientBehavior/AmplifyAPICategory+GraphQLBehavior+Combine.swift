//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

extension APICategoryGraphQLBehavior {

    /// <#Description#>
    /// - Parameter request: <#request description#>
    /// - Returns: <#description#>
    public func query<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        query(request: request, listener: nil)
    }

    /// <#Description#>
    /// - Parameter request: <#request description#>
    /// - Returns: <#description#>
    public func mutate<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLOperation<R> {
        mutate(request: request, listener: nil)
    }

    /// <#Description#>
    /// - Parameter request: <#request description#>
    /// - Returns: <#description#>
    public func subscribe<R>(request: GraphQLRequest<R>) -> GraphQLSubscriptionOperation<R> {
        subscribe(request: request, valueListener: nil, completionListener: nil)
    }
}
