//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// A publisher that returns values from `query` and `mutate` GraphQL operations
public typealias GraphQLPublisher<R: Decodable> = AnyPublisher<
    GraphQLResponse<R>,
    APIError
>

/// A publisher that returns values from a GraphQL `subscribe` operation. Subscription events delivered
/// in the result stream may include GraphQL errors (such as partially-decoded results), but those
/// errors do not represent the end of the subscription stream. The publisher will emit a `completion`
/// when the subscription is terminated and no longer receiving updates.
public typealias GraphQLSubscriptionPublisher<R: Decodable> = AnyPublisher<
    SubscriptionEvent<GraphQLResponse<R>>,
    APIError
>

public extension APICategoryGraphQLBehavior {

    /// Perform a GraphQL query operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    ///   - listener: The event listener for the operation
    /// - Returns: A publisher that can be observed for results
    func query<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLPublisher<R> {
        Future { promise in
            _ = self.query(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform a GraphQL mutate operation against a previously configured API. This operation
    /// will be asynchronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    ///   - listener: The event listener for the operation
    /// - Returns: A publisher that can be observed for results
    func mutate<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLPublisher<R> {
        Future { promise in
            _ = self.mutate(request: request) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Perform a GraphQL subscribe operation against a previously configured API. This operation
    /// will be asychronous, with the callback accessible both locally and via the Hub.
    ///
    /// - Parameters:
    ///   - request: The GraphQL request containing apiName, document, variables, and responseType
    /// - Returns: A publisher that can be observed for subscription events or completion of the subscription
    func subscribe<R: Decodable>(request: GraphQLRequest<R>) -> GraphQLSubscriptionPublisher<R> {
        let subscriptionSubject = PassthroughSubject<SubscriptionEvent<GraphQLResponse<R>>, APIError>()

        // Retain the operation inside the subscription, and release it when it is done. Note that this
        // pattern doesn't allow callers to cancel the subscription
        var operation: GraphQLSubscriptionOperation<R>!
        operation = subscribe(
            request: request,
            valueListener: { subscriptionSubject.send($0) },
            completionListener: { result in
                switch result {
                case .success:
                    subscriptionSubject.send(completion: .finished)
                case .failure(let apiError):
                    subscriptionSubject.send(completion: .failure(apiError))
                }

                // We don't technically need this if check, but it prevents the compiler from warning about
                // 'operation' being written to but never read
                if operation != nil {
                    operation = nil
                }
        })

        return subscriptionSubject.eraseToAnyPublisher()
    }
}
