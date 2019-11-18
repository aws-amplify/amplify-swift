//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

/// An asynchronous queue composed of Combine publishers. This queue has a maximum event limit of 10,000 items.
///
/// (Although this is a rehash of Combine's behavior, it's slightly confusing, and worth a discussion of the intent to
/// aid in future troubleshooting.)
///
/// The queue's events are the concatentation of:
/// - Previously loaded mutation events
/// - Incoming mutation events
///
/// That queue is constructed by concatenating a Record of previously loaded events with a PassthroughSubject for new
/// events. (We could also `prepend` the Passthrough with the previously loaded events to accomplish the same thing.)
/// To make sure we get all the events, we set up a buffer to capture incoming events before the subscription starts.
///
/// **Expected flow:**
/// - Mutation queue loads mutations, listens for incoming mutations, buffers
/// - Mutation queue subscribes an incoming subscriber to the pending mutations publisher
/// - Background: whenever an incoming mutation event is received, `send` it to `incomingMutations`
/// - subscriber requests one event from pendingMutations publisher
/// - subscriber sends event to API
/// - subscriber gets success back
/// - subscriber dequeues mutation event
/// - subscriber requests next event
final class OutgoingMutationQueue {
    weak var storageEngine: StorageEngineBehavior?

    /// Incoming mutations are enqueued into this subject
    private let incomingMutations: PassthroughSubject<MutationEvent, DataStoreError>

    /// Pending mutations are published from this publisher into the subscriber
    private var pendingMutations: AnyPublisher<MutationEvent, DataStoreError>?

    init(storageEngine: StorageEngineBehavior) {
        self.storageEngine = storageEngine
        self.incomingMutations = PassthroughSubject()

        // TODO: Find the right place to do this
        ModelRegistry.register(modelType: MutationEvent.self)
    }

    func subscribe<S: Subscriber>(subscriber: S)
        where S.Input == MutationEvent, S.Failure == DataStoreError {
            pendingMutations = Publishers.Concatenate(
                prefix: loadStoredMutations(),
                suffix: incomingMutations)
                .buffer(size: 10_000,
                        prefetch: .keepFull,
                        whenFull: .dropOldest)
                .eraseToAnyPublisher()

            pendingMutations?.subscribe(subscriber)
    }

    func enqueue(event: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        Future<MutationEvent, DataStoreError> { future in
            guard let storageEngine = self.storageEngine else {
                let error = DataStoreError.configuration(
                    "storageEngine is nil inside of OutgoingMutationQueue.enqueue",
                    """
                    The reference to storageEngine has been released while an ongoing mutation was being processed.
                    There is a possibility that there is a bug if this error persists. Please take a look at
                    https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                    match your scenario, and file an issue with the details of the bug if there isn't.
                    """
                )
                future(.failure(error))
                return
            }

            storageEngine.save(event) {
                switch $0 {
                case .result:
                    self.incomingMutations.send(event)
                    future(.success(event))
                case .error(let error):
                    future(.failure(error))
                }
            }
        }
    }

    func dequeue(event: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        Future<MutationEvent, DataStoreError> { future in
            guard let storageEngine = self.storageEngine else {
                let error = DataStoreError.configuration(
                    "storageEngine is nil inside of OutgoingMutationQueue.enqueue",
                    """
                    The reference to storageEngine has been released while an ongoing mutation was being processed.
                    There is a possibility that there is a bug if this error persists. Please take a look at
                    https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                    match your scenario, and file an issue with the details of the bug if there isn't.
                    """
                )
                future(.failure(error))
                return
            }

            storageEngine.delete(MutationEvent.self, withId: event.id) {
                switch $0 {
                case .result:
                    future(.success(event))
                case .error(let error):
                    future(.failure(error))
                }
            }
        }
    }

    // MARK: - Private

    private func loadStoredMutations() -> AnyPublisher<MutationEvent, DataStoreError> {
        return Record { record in
            guard let storageEngine = self.storageEngine else {
                let error = DataStoreError.configuration(
                    "storageEngine is nil inside of OutgoingMutationQueue.enqueue",
                    """
                    The reference to storageEngine has been released while an ongoing mutation was being processed.
                    There is a possibility that there is a bug if this error persists. Please take a look at
                    https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                    match your scenario, and file an issue with the details of the bug if there isn't.
                    """
                )
                record.receive(completion: .failure(error))
                return
            }

            storageEngine.query(MutationEvent.self, predicate: nil) {
                let unsortedEvents: [MutationEvent]
                switch $0 {
                case .result(let events):
                    unsortedEvents = events
                case .error(let error):
                    record.receive(completion: .failure(error))
                    return
                }

                let sortedEvents = unsortedEvents.sorted { $0.createdAt < $1.createdAt }
                sortedEvents.forEach { record.receive($0) }
                record.receive(completion: .finished)
            }
        }.eraseToAnyPublisher()
    }

}
