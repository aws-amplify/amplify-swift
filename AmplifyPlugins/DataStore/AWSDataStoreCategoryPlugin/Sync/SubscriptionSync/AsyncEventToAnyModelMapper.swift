//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Subscribes to an IncomingSUbscriptionAsyncEventQueue, and publishes AnyModel
final class AsyncEventToAnyModelMapper: Subscriber {
    typealias Input = IncomingSubscriptionAsyncEventQueue.QueueElement
    typealias Failure = DataStoreError

    var subscription: Subscription?

    private let incomingSubscriptionEvents: PassthroughSubject<AnyModel, DataStoreError>

    var publisher: AnyPublisher<AnyModel, DataStoreError> {
        incomingSubscriptionEvents.eraseToAnyPublisher()
    }

    init(asyncEventQueue: IncomingSubscriptionAsyncEventQueue) {
        let incomingSubscriptionEvents = PassthroughSubject<AnyModel, DataStoreError>()
        self.incomingSubscriptionEvents = incomingSubscriptionEvents
        asyncEventQueue.subscribe(subscriber: self)
    }

    // MARK: - Subscriber

    func receive(subscription: Subscription) {
        log.info("received subscription: \(subscription)")
        self.subscription = subscription
        subscription.request(.max(1))
    }

    func receive(_ input: IncomingSubscriptionAsyncEventQueue.QueueElement) -> Subscribers.Demand {
        log.verbose("received event: \(input)")
        switch input {
        case .completed:
            log.debug("received completed event: \(input)")
            incomingSubscriptionEvents.send(completion: .finished)
        case .failed(let apiError):
            let dataStoreError = DataStoreError.api(apiError)
            log.error(error: dataStoreError)
            incomingSubscriptionEvents.send(completion: .failure(dataStoreError))
            return .max(1)
        case .inProcess(let subscriptionEvent):
            dispose(of: subscriptionEvent)
        default:
            break
        }
        return .none
    }

    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.info("received completion: \(completion)")
    }

    // MARK: - Event processing

    private func dispose(of subscriptionEvent: SubscriptionEvent<GraphQLResponse<AnyModel>>) {
        switch subscriptionEvent {
        case .connection(let connectionState):
            log.info("connectionState now \(connectionState)")
        case .data(let graphQLResponse):
            dispose(of: graphQLResponse)
        }
    }

    private func dispose(of graphQLResponse: GraphQLResponse<AnyModel>) {
        switch graphQLResponse {
        case .success(let anyModel):
            incomingSubscriptionEvents.send(anyModel)
            subscription?.request(.max(1))
        case .error(let graphQLErrors):
            log.error("Received graphql errors: \(graphQLErrors)")
        case .partial(_, let graphQLErrors):
            log.error("Received partial response with graphql errors: \(graphQLErrors)")
        case .transformationError(let rawResponse, let apiError):
            log.error("Unable to transform raw response into AnyModel: \(apiError)\nRaw response:\n\(rawResponse)")
        }
    }
}

extension AsyncEventToAnyModelMapper: DefaultLogger { }
