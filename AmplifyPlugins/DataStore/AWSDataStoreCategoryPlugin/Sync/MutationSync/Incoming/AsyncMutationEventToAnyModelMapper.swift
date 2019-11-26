//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Subscribes to an IncomingSubscriptionAsyncEventQueue, and publishes AnyModel
final class AsyncMutationEventToAnyModelMapper: Subscriber {
    typealias Input = IncomingAsyncMutationEventSubject.Event
    typealias Failure = DataStoreError

    var subscription: Subscription?

    private let modelsFromMutation: PassthroughSubject<AnyModel, DataStoreError>

    var publisher: AnyPublisher<AnyModel, DataStoreError> {
        modelsFromMutation.eraseToAnyPublisher()
    }

    init() {
        self.modelsFromMutation = PassthroughSubject<AnyModel, DataStoreError>()
    }

    // MARK: - Subscriber

    func receive(subscription: Subscription) {
        log.info("received subscription: \(subscription)")
        self.subscription = subscription
        subscription.request(.max(1))
    }

    /// Receives an async mutation event and republishes as an AnyModel. Note that this receiver never sends a
    /// completion to the downstream subscribers, since it consumes upstream events on an as-needed basis, which are
    /// populated from on-demand network operations.
    func receive(_ input: IncomingAsyncMutationEventSubject.Event) -> Subscribers.Demand {
        log.verbose("\(#function): \(input)")

        switch input {
        case .completed(let graphQLResponse):
            log.debug("received graphQLResponse: \(graphQLResponse)")
            dispose(of: graphQLResponse)
        case .failed(let apiError):
            let dataStoreError = DataStoreError.api(apiError)
            log.error(error: dataStoreError)
        case .inProcess:
            // Mutation events do not have an inProcess value
            break
        default:
            break
        }
        return .max(1)
    }

    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.info("received completion: \(completion)")
    }

    // MARK: - Event processing

    private func dispose(of graphQLResponse: GraphQLResponse<AnyModel>) {
        log.verbose("dispose(of graphQLResponse): \(graphQLResponse)")
        switch graphQLResponse {
        case .success(let anyModel):
            modelsFromMutation.send(anyModel)
        case .failure(let failure):
            switch failure {
            case .error(let graphQLErrors):
                log.error("Received graphql errors: \(graphQLErrors)")
            case .partial(_, let graphQLErrors):
                log.error("Received partial response with graphql errors: \(graphQLErrors)")
            case .transformationError(let rawResponse, let apiError):
                log.error("Unable to transform raw response into AnyModel: \(apiError)\nRaw response:\n\(rawResponse)")
            }
        }
    }
}

extension AsyncMutationEventToAnyModelMapper: DefaultLogger { }
