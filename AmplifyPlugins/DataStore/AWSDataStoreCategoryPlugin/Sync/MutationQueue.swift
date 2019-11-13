//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

typealias MutationEventSubject = PassthroughSubject<MutationEvent, DataStoreError>

typealias MutationEventFuture = Future<MutationEvent, DataStoreError>

typealias PendingMutationEvents = Record<MutationEvent, DataStoreError>

typealias MutationEventPublisher = AnyPublisher<MutationEvent, DataStoreError>

final class MutationQueue {

    let storageAdapter: StorageEngineAdapter
    let pendingMutations: MutationEventSubject

    internal init(pendingMutations: MutationEventSubject = MutationEventSubject(),
                  storageAdapter: StorageEngineAdapter) {
        self.pendingMutations = pendingMutations
        self.storageAdapter = storageAdapter
    }

    func enqueue(event: MutationEvent) -> MutationEventPublisher {
        return Deferred {
            MutationEventFuture { future in
                self.storageAdapter.save(event) {
                    switch $0 {
                    case .result:
                        // TODO revisit this (should we call future after append is resolved?)
                        _ = self.pendingMutations.append(event)
                        future(.success(event))
                    case .error(let error):
                        future(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    func dequeue(event: MutationEvent) -> MutationEventPublisher {
        return Deferred {
            MutationEventFuture { future in
                self.storageAdapter.delete(MutationEvent.self, withId: event.id) {
                    switch $0 {
                    case .result:
                        future(.success(event))
                    case .error(let error):
                        future(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    func previouslyPendingMutations() -> MutationEventPublisher {
        return Deferred {
            PendingMutationEvents { record in
                // TODO sort order?
                self.storageAdapter.query(MutationEvent.self, predicate: nil) {
                    switch $0 {
                    case .result(let events):
                        events.forEach { event in
                            record.receive(event)
                        }
                        record.receive(completion: .finished)
                    case .error(let error):
                        record.receive(completion: .failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }

    func observe() -> MutationEventPublisher {
        return pendingMutations
            .prepend(previouslyPendingMutations())
            .filter { event in event.source != .syncEngine }
            .eraseToAnyPublisher()
    }
}
