//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Ingests MutationEvents from and writes them to the MutationEvent persistent store
protocol MutationEventIngester: class {
    func start() -> Future<Void, DataStoreError>
    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError>
}

/// Publishes mutation events to downstream subscribers for subsequent sync to the API.
protocol MutationEventPublisher: class {
    var publisher: AnyPublisher<MutationEvent, DataStoreError> { get }
}

final class AWSMutationEventIngester: MutationEventIngester, MutationEventPublisher {
    typealias SavedEventPromise = Future<MutationEvent, DataStoreError>.Promise

    // Mutation writes must be serially applied
    private let workQueue = DispatchQueue(label: "com.amazonaws.MutationEventIngester",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?

    private let savedEvents: PassthroughSubject<MutationEvent, DataStoreError>

    var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        return savedEvents.eraseToAnyPublisher()
    }

    init(storageAdapter: StorageEngineAdapter) {
        self.storageAdapter = storageAdapter
        self.savedEvents = PassthroughSubject()
    }

    func start() -> Future<Void, DataStoreError> {
        return loadSavedMutationEvents()
    }

    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        return Future { promise in
            guard let storageAdapter = self.storageAdapter else {
                let dataStoreError = DataStoreError.configuration(
                    "storageAdapter is unexpectedly nil",
                    """
                    The reference to storageAdapter has been released while an ongoing mutation was being processed.
                    There is a possibility that there is a bug if this error persists. Please take a look at
                    https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                    match your scenario, and file an issue with the details of the bug if there isn't.
                    """
                )
                promise(.failure(dataStoreError))
                return
            }

            storageAdapter.save(mutationEvent) {
                switch $0 {
                case .failure(let dataStoreError):
                    promise(.failure(dataStoreError))
                case .success(let savedMutationEvent):
                    promise(.success(savedMutationEvent))
                    self.publish(mutationEvents: [savedMutationEvent])
                }
            }
        }
    }

    /// Loads saved mutation events from the database and
    private func loadSavedMutationEvents() -> Future<Void, DataStoreError> {
        return Future { promise in
            guard let storageAdapter = self.storageAdapter else {
                let dataStoreError = DataStoreError.configuration(
                    "storageAdapter is unexpectedly nil",
                    """
                    The reference to storageAdapter has been released while an ongoing mutation was being processed.
                    There is a possibility that there is a bug if this error persists. Please take a look at
                    https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                    match your scenario, and file an issue with the details of the bug if there isn't.
                    """
                )
                promise(.failure(dataStoreError))
                return
            }

            storageAdapter.query(MutationEvent.self, predicate: nil) { result in
                switch result {
                case .failure(let dataStoreError):
                    promise(.failure(dataStoreError))
                case .success(let mutationEvents):
                    self.publish(mutationEvents: mutationEvents)
                    promise(.success(()))
                }
            }
        }
    }

    private func publish(mutationEvents: [MutationEvent]) {
        for event in mutationEvents {
            savedEvents.send(event)
        }
    }
}
