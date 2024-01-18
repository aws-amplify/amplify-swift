//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension APICategory: APICategoryGraphQLBehavior {

    // MARK: - Request-based GraphQL operations
    public func query<R: Decodable>(request: GraphQLRequest<R>) async throws -> GraphQLTask<R>.Success {
        try await plugin.query(request: request)
    }

    @available(customCondition, introduced: 1.0)
    public func mutate<R: Decodable>(request: GraphQLRequest<R>) async throws -> GraphQLTask<R>.Success {
        try await plugin.mutate(request: request)
    }

    public func subscribe<R>(request: GraphQLRequest<R>) -> AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<R>> {
        plugin.subscribe(request: request)
    }
}
// Check if a custom condition is met
func isCustomConditionMet() -> Bool {
    // Your custom conditions go here
    return true // Replace with your actual condition logic
}
