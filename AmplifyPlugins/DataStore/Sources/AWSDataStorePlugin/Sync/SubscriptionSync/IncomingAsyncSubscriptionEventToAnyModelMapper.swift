//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

enum IncomingAsyncSubscriptionEvent {
    case payload(MutationSync<AnyModel>)
    case connectionConnected
    case connectionDisconnected
}

// swiftlint:disable type_name
/// Subscribes to an IncomingSubscriptionAsyncEventQueue, and publishes AnyModel
final class IncomingAsyncSubscriptionEventToAnyModelMapper: Subscriber, AmplifyCancellable {
    // swiftlint:enable type_name

    typealias Input = IncomingAsyncSubscriptionEventPublisher.Event
    typealias Failure = DataStoreError
    typealias Payload = MutationSync<AnyModel>

    var subscription: Subscription?
    var taskQueue: TaskQueue<Void>

    private let modelsFromSubscription: PassthroughSubject<IncomingAsyncSubscriptionEvent, DataStoreError>

    var publisher: AnyPublisher<IncomingAsyncSubscriptionEvent, DataStoreError> {
        modelsFromSubscription.eraseToAnyPublisher()
    }

    init() {
        self.modelsFromSubscription = PassthroughSubject<IncomingAsyncSubscriptionEvent, DataStoreError>()
        self.taskQueue = TaskQueue<Void>()
    }

    // MARK: - Subscriber

    func receive(subscription: Subscription) {
        log.info("Received subscription: \(subscription)")
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    func receive(_ subscriptionEvent: IncomingAsyncSubscriptionEventPublisher.Event) -> Subscribers.Demand {
        log.verbose("\(#function): \(subscriptionEvent)")
        self.dispose(of: subscriptionEvent)

        return .unlimited
    }

    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.info("Received completion: \(completion)")
        modelsFromSubscription.send(completion: completion)
    }

    // MARK: - Event processing

    private func dispose(of subscriptionEvent: GraphQLSubscriptionEvent<Payload>) {
        taskQueue.async { [weak self] in
            guard let self else { return }

            log.verbose("dispose(of subscriptionEvent): \(subscriptionEvent)")
            switch subscriptionEvent {
            case .connection(let connectionState):
                // Connection events are informational only at this level. The terminal state is represented by the
                // OperationResult.
                log.info("connectionState now \(connectionState)")
                switch connectionState {
                case .connected:
                    modelsFromSubscription.send(.connectionConnected)
                case .disconnected:
                    modelsFromSubscription.send(.connectionDisconnected)
                default:
                    break
                }
            case .data(let graphQLResponse):
                dispose(of: graphQLResponse)
            }
        }
    }

    private func dispose(of graphQLResponse: GraphQLResponse<Payload>) {
        log.verbose("dispose(of graphQLResponse): \(graphQLResponse)")
        switch graphQLResponse {
        case .success(let mutationSync):
            modelsFromSubscription.send(.payload(mutationSync))
        case .failure(let failure):
            log.error(error: failure)
        }
    }

    func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}

extension IncomingAsyncSubscriptionEventToAnyModelMapper: Resettable {
    func reset() async {
        log.verbose("Resetting modelsFromSubscription and subscription")
        modelsFromSubscription.send(completion: .finished)
        subscription?.cancel()
        subscription = nil
        log.verbose("Resetting modelsFromSubscription and subscription: finished")
    }
}

extension IncomingAsyncSubscriptionEventToAnyModelMapper: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
