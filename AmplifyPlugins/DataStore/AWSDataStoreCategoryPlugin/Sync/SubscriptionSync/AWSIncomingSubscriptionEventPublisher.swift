//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Facade to hide the AsyncEventQueue/ModelMapper structures from the ModelReconciliationQueue.
/// Provides a publisher for all incoming subscription types (onCreate, onUpdate, onDelete) for a single Model type.
@available(iOS 13.0, *)
final class AWSIncomingSubscriptionEventPublisher: IncomingSubscriptionEventPublisher {

    private let asyncEvents: IncomingAsyncSubscriptionEventPublisher
    private var mapper: IncomingAsyncSubscriptionEventToAnyModelMapper?
    private let subscriptionEventSubject: PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>
    private var mapperSink: AnyCancellable?
    private var connectedConnections: Int
    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> {
        return subscriptionEventSubject.eraseToAnyPublisher()
    }

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        self.subscriptionEventSubject = PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>()
        self.asyncEvents = IncomingAsyncSubscriptionEventPublisher(modelType: modelType,
                                                                   api: api)

        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        self.mapper = mapper

        asyncEvents.subscribe(subscriber: mapper)
        self.connectedConnections = 0
        self.mapperSink = mapper.publisher.sink(receiveCompletion: onReceiveCompletion(receiveCompletion:),
                                                receiveValue: onReceive(receiveValue:))
    }

    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        subscriptionEventSubject.send(completion: receiveCompletion)
    }

    private func onReceive(receiveValue: IncomingAsyncSubscriptionEvent) {
        //TODO: Update async subscription event code to pass through type of connected connection
        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()

        switch receiveValue {
        case .connectionConnected:
            connectedConnections += 1
        case .connectionDisconnected:
            if connectedConnections > 0 {
                connectedConnections -= 1
            }
        default:
            break
        }
        if connectedConnections == 3 {
            subscriptionEventSubject.send(.connectionConnected)
        } else if connectedConnections > 3 {
            print("MORE CONNECTIONS THAN REQUIRD!?!?!?!?!")
        }
        semaphore.signal()

        if case .payload(let mutationSyncAnyModel) = receiveValue {
            subscriptionEventSubject.send(.mutationEvent(mutationSyncAnyModel))
        }
    }

    func cancel() {
        mapperSink?.cancel()
        mapperSink = nil

        asyncEvents.cancel()
        mapper = nil
    }
}

@available(iOS 13.0, *)
extension AWSIncomingSubscriptionEventPublisher: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            self.asyncEvents.reset { group.leave() }
        }

        group.enter()
        DispatchQueue.global().async {
            self.mapper?.reset { group.leave() }
        }

        group.wait()
        onComplete()
    }

}
