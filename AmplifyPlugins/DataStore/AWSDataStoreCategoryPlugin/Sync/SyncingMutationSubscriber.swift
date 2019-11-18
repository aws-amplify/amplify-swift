//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Receives incoming mutation events and syncs them to the cloud API. Processes one event at a time, to ensure we fully
/// resolve a given mutation event's lifecycle before attempting the next one.
class SyncEngineMutationSubscriber {
    let api: APICategoryGraphQLBehavior

    /// Holds the subscription to the upstream publisher that delivers mutation events.
    private var subscription: Subscription?

    init(api: APICategoryGraphQLBehavior) {
        self.api = api
    }

    // MARK: - Sync

    private func syncToCloud(mutationEvent: MutationEvent) -> AnyPublisher<String, DataStoreError> {
        guard let model = ModelRegistry.modelType(from: mutationEvent.modelName) else {
            let error = DataStoreError.invalidModelName(mutationEvent.modelName)
            return Fail(error: error).eraseToAnyPublisher()
        }

        // TODO: Get an actual GraphQL request from the model
        print("Not yet getting a real GraphQL request for \(model)")
        let request = GraphQLRequest<String>(document: "{do a mutation}",
                                             variables: nil,
                                             responseType: String.self)
        return Future { future in
            _ = self.api.mutate(request: request) { mutationResponse in
                switch mutationResponse {
                case .completed(let graphQLResponse):
                    SyncEngineMutationSubscriber.resolve(future: future, graphQLResponse: graphQLResponse)
                case .failed(let apiError):
                    future(.failure(DataStoreError.api(apiError)))
                default:
                    break
                }
            }
            print("Syncing to cloud: \(mutationEvent)")

        }.eraseToAnyPublisher()
    }

    // MARK: - Response handling

    private static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                              graphQLResponse: GraphQLResponse<R>) {
        switch graphQLResponse {
        case .success(let successResponse):
            future(.success(successResponse))
        case .error(let graphQLErrors):
            resolve(future: future, graphQLErrors: graphQLErrors)
        case .partial(let partialResponse, let graphQLErrors):
            resolve(future: future, partialResponse: partialResponse, graphQLErrors: graphQLErrors)
        case .transformationError(let rawResponse, let transformationError):
            resolve(future: future, rawResponse: rawResponse, transformationError: transformationError)
        }

    }

    // MARK: - Error handling

    private static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                              graphQLErrors: [GraphQLError]) {
        let syncError = DataStoreError.sync(
            "Sync failed with GraphQL errors from service",
            """
            Inspect the errors for more details:
            \(graphQLErrors)
            """
        )
        future(.failure(syncError))
    }

    private static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                              partialResponse: R,
                                              graphQLErrors: [GraphQLError]) {
        let syncError = DataStoreError.sync(
            "Sync failed with a partial response from service",
            """
            Partial response:
            \(partialResponse)

            Inspect the errors for more details:
            \(graphQLErrors)
            """
        )
        future(.failure(syncError))
    }

    private static func resolve<R: Decodable>(future: Future<R, DataStoreError>.Promise,
                                              rawResponse: RawGraphQLResponse,
                                              transformationError: APIError) {
        let syncError = DataStoreError.sync(
            "Sync failed because it was not able to decode the response into the specified result type",
            """
            Sync failed trying to decode the raw response below into \(String(describing: R.self)). \
            See underlying error for more information. Raw response:
            \(rawResponse)
            """,
            transformationError
        )
        future(.failure(syncError))
    }

}

// MARK: - Subscriber

extension SyncEngineMutationSubscriber: Subscriber {
    typealias Input = MutationEvent
    typealias Failure = DataStoreError

    /// Receives the subscription from the publisher and immediately requests one event
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }

    /// Receives one input event and submits it for syncing. Once its processing is complete, requests a new event from
    /// the subscription
    func receive(_ input: MutationEvent) -> Subscribers.Demand {

        // The `sink` completion handlers below must hold onto this reference, or else Combine cancels it when the
        // method returns. To prevent retains, be sure to set the subscription to `nil` inside each of the sink
        // `receive` events
        var syncSubscription: AnyCancellable?

        syncSubscription = syncToCloud(mutationEvent: input).sink(
            receiveCompletion: { completion in
                print("Subscription received completion: \(completion)")
                syncSubscription?.cancel()
                syncSubscription = nil
        }, receiveValue: { value in
            print("Subscription received value: \(value)")
            self.subscription?.request(.max(1))
            syncSubscription?.cancel()
            syncSubscription = nil
        })

        // Return `.none` from this method, because we don't want to request a new input until after we've fully
        // resolved the current one. That resolution may include network traffic, conflict resolution, and error
        // retries
        return .none
    }

    /// Receives a completion from the publisher and releases the subscription
    func receive(completion: Subscribers.Completion<DataStoreError>) {
        // TODO: Log.info
        print("MySubscriber Received completion: \(completion)")

        // TODO: Does this need to notify anybody upstream to nil out the SyncEngineMutationSubscriber instance?
        subscription = nil
    }

}
