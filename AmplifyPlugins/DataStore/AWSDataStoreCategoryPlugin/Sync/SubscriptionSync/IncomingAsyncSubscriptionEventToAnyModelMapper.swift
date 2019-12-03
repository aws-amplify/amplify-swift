//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

// swiftlint:disable type_name
/// Subscribes to an IncomingSubscriptionAsyncEventQueue, and publishes AnyModel
@available(iOS 13, *)
final class IncomingAsyncSubscriptionEventToAnyModelMapper: Subscriber {
    // swiftlint:enable type_name

    typealias Input = IncomingAsyncSubscriptionEventPublisher.Event
    typealias Failure = DataStoreError
    typealias Payload = MutationSync<AnyModel>

    var subscription: Subscription?

    private let modelsFromSubscription: PassthroughSubject<Payload, DataStoreError>

    var publisher: AnyPublisher<Payload, DataStoreError> {
        modelsFromSubscription.eraseToAnyPublisher()
    }

    init() {
        self.modelsFromSubscription = PassthroughSubject<Payload, DataStoreError>()
    }

    // MARK: - Subscriber

    func receive(subscription: Subscription) {
        log.info("Received subscription: \(subscription)")
        self.subscription = subscription
        subscription.request(.max(1))
    }

    func receive(_ input: IncomingAsyncSubscriptionEventPublisher.Event) -> Subscribers.Demand {
        log.verbose("\(#function): \(input)")

        switch input {
        case .completed:
            log.debug("Received completed event: \(input)")
            modelsFromSubscription.send(completion: .finished)
        case .failed(let apiError):
            let dataStoreError = DataStoreError.api(apiError)
            log.error(error: dataStoreError)
            modelsFromSubscription.send(completion: .failure(dataStoreError))
        case .inProcess(let subscriptionEvent):
            dispose(of: subscriptionEvent)
        default:
            break
        }
        return .max(1)
    }

    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.info("Received completion: \(completion)")
    }

    // MARK: - Event processing

    private func dispose(of subscriptionEvent: SubscriptionEvent<GraphQLResponse<Payload>>) {
        log.verbose("dispose(of subscriptionEvent): \(subscriptionEvent)")
        switch subscriptionEvent {
        case .connection(let connectionState):
            // Connection events are informational only at this level. The terminal state is represented at the
            // AsyncEvent Completion/Error
            log.info("connectionState now \(connectionState)")
        case .data(let graphQLResponse):
            dispose(of: graphQLResponse)
        }
    }

    private func dispose(of graphQLResponse: GraphQLResponse<Payload>) {
        log.verbose("dispose(of graphQLResponse): \(graphQLResponse)")
        switch graphQLResponse {
        case .success(let mutationSync):
            modelsFromSubscription.send(mutationSync)
        case .failure(let failure):
            log.error(error: failure)
        }
    }

    func reset(onComplete: () -> Void) {
        modelsFromSubscription.send(completion: .finished)
        subscription?.cancel()
        subscription = nil
        onComplete()
    }
}

@available(iOS 13, *)
extension IncomingAsyncSubscriptionEventToAnyModelMapper: DefaultLogger { }
