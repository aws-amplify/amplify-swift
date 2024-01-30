//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

/// Facade to hide the AsyncEventQueue/ModelMapper structures from the ModelReconciliationQueue.
/// Provides a publisher for all incoming subscription types (onCreate, onUpdate, onDelete) for a single Model type.
final class AWSIncomingSubscriptionEventPublisher: IncomingSubscriptionEventPublisher {

    private let asyncEvents: IncomingAsyncSubscriptionEventPublisher
    //private let mapper: IncomingAsyncSubscriptionEventToAnyModelMapper
    private let subscriptionEventSubject: PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>
    private var mapperSink: AnyCancellable?
    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> {
        return subscriptionEventSubject.eraseToAnyPublisher()
    }

    typealias Payload = MutationSync<AnyModel>

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehaviorExtended,
         modelPredicate: QueryPredicate?,
         auth: AuthCategoryBehavior?,
         authModeStrategy: AuthModeStrategy,
         incomingSubscriptionEventsOrderingQueue: TaskQueue<Void>) async {
        self.subscriptionEventSubject = PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>()
        self.asyncEvents = await IncomingAsyncSubscriptionEventPublisher(modelSchema: modelSchema,
                                                                         api: api,
                                                                         modelPredicate: modelPredicate,
                                                                         auth: auth,
                                                                         authModeStrategy: authModeStrategy,
                                                                         incomingSubscriptionEventsOrderingQueue: incomingSubscriptionEventsOrderingQueue)

        //self.mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        //asyncEvents.subscribe(subscriber: mapper)
        self.mapperSink = asyncEvents.publisher.sink { [weak self] completion in
            guard let self else { return }
            self.subscriptionEventSubject.send(completion: completion)
        } receiveValue: { [weak self] event in
            guard let self else { return }
            incomingSubscriptionEventsOrderingQueue.async { [weak self] in
                guard let self else { return }
                self.dispose(of: event)
            }
        }

//        self.mapperSink = mapper
//            .publisher
//            .sink(
//                receiveCompletion: { [weak self] in self?.onReceiveCompletion(receiveCompletion: $0) },
//                receiveValue: { [weak self] in self?.onReceive(receiveValue: $0) }
//            )
    }

    private func dispose(of subscriptionEvent: GraphQLSubscriptionEvent<Payload>) {


        log.verbose("dispose(of subscriptionEvent): \(subscriptionEvent)")
        switch subscriptionEvent {
        case .connection(let connectionState):
            // Connection events are informational only at this level. The terminal state is represented by the
            // OperationResult.
            log.info("connectionState now \(connectionState)")
            switch connectionState {
            case .connected:
                subscriptionEventSubject.send(.connectionConnected)
            case .disconnected:
                // subscriptionEventSubject.send(.connectionDisconnected)
                break
            default:
                break
            }
        case .data(let graphQLResponse):
            dispose(of: graphQLResponse)
        }
    }

    private func dispose(of graphQLResponse: GraphQLResponse<Payload>) {
        log.verbose("dispose(of graphQLResponse): \(graphQLResponse)")
        switch graphQLResponse {
        case .success(let mutationSync):
            subscriptionEventSubject.send(.mutationEvent(mutationSync))
        case .failure(let failure):
            log.error(error: failure)
        }
    }

    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        subscriptionEventSubject.send(completion: receiveCompletion)
    }

    private func onReceive(receiveValue: IncomingAsyncSubscriptionEvent) {
        if case .connectionConnected = receiveValue {
            subscriptionEventSubject.send(.connectionConnected)
        } else if case .payload(let mutationSyncAnyModel) = receiveValue {
            subscriptionEventSubject.send(.mutationEvent(mutationSyncAnyModel))
        }
    }

    func cancel() {
        mapperSink?.cancel()
        mapperSink = nil

        asyncEvents.cancel()
        //mapper.cancel()
    }
}

// MARK: Resettable
extension AWSIncomingSubscriptionEventPublisher: Resettable {

    func reset() async {
        Amplify.log.verbose("Resetting asyncEvents")
        asyncEvents.reset()
        Amplify.log.verbose("Resetting asyncEvents: finished")

//        Amplify.log.verbose("Resetting mapper")
//        await mapper.reset()
//        Amplify.log.verbose("Resetting mapper: finished")
    }

}

extension AWSIncomingSubscriptionEventPublisher: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
