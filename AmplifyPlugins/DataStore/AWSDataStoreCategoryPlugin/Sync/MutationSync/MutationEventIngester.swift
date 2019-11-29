//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Ingests MutationEvents from and writes them to the MutationEvent persistent store
@available(iOS 13.0, *)
protocol MutationEventIngester: class {
    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError>
}

@available(iOS 13.0, *)
/// Interface for saving and loading MutationEvents from storage
final class AWSMutationDatabaseAdapter: MutationEventIngester {

    weak var storageAdapter: StorageEngineAdapter?

    /// If a request for 'next event' comes in while the queue is empty, this promise will be set, so that the next
    /// saved event can fulfill it
    var nextEventPromise: Future<MutationEvent, DataStoreError>.Promise?

    /// Loads saved events from the database and delivers them to `mutationEventSubject`
    init(storageAdapter: StorageEngineAdapter) throws {
        self.storageAdapter = storageAdapter
        log.verbose("Initialized")
    }

    /// Accepts a mutation event and writes it to the local database, then submits it to `mutationEventSubject`
    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        log.verbose("\(#function): \(mutationEvent)")

        return Future { promise in
            guard let storageAdapter = self.storageAdapter else {
                let dataStoreError = DataStoreError.configuration(
                    "storageAdapter is unexpectedly nil in an internal operation",
                    """
                    The reference to storageAdapter has been released while an ongoing mutation was being processed.
                    """
                )
                promise(.failure(dataStoreError))
                return
            }

            storageAdapter.save(mutationEvent) {
                if case .success(let savedMutationEvent) = $0 {
                    self.log.verbose("\(#function): saved \(savedMutationEvent)")
                    if let nextEventPromise = self.nextEventPromise {
                        nextEventPromise(.success(savedMutationEvent))
                        self.nextEventPromise = nil
                    }
                }
                promise($0)
            }
        }
    }

    /// Resolves conflicts for the offered mutationEvent, and either accepts the event, returning a disposition, or
    /// rejects the event with an error
    func resolveConflicts(for mutationEvent: MutationEvent,
                          storageAdapter: StorageEngineAdapter) -> Result<MutationEvent, DataStoreError> {
        fatalError("Not yet implemented")
    }

    func reset(onComplete: () -> Void) {
        storageAdapter = nil
        onComplete()
    }

}

@available(iOS 13.0, *)
extension AWSMutationDatabaseAdapter: DefaultLogger { }
