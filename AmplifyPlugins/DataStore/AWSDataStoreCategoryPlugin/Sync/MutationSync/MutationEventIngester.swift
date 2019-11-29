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
final class AWSMutationEventIngester: MutationEventIngester {

    private weak var storageAdapter: StorageEngineAdapter?
    private weak var mutationEventSubject: MutationEventSubject?

    /// Loads saved events from the database and delivers them to `mutationEventSubject`
    init(storageAdapter: StorageEngineAdapter, mutationEventSubject: MutationEventSubject) throws {
        self.storageAdapter = storageAdapter
        self.mutationEventSubject = mutationEventSubject

        let savedMutations = try loadSavedMutationEvents(storageAdapter: storageAdapter)
        for event in savedMutations {
            mutationEventSubject.publish(mutationEvent: event)
        }
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
                    self.log.verbose("\(#function): saved \(mutationEvent)")
                    self.mutationEventSubject?.publish(mutationEvent: savedMutationEvent)
                }
                promise($0)
            }
        }
    }

    /// Loads saved mutation events from the database. This method blocks.
    func loadSavedMutationEvents(storageAdapter: StorageEngineAdapter) throws -> [MutationEvent] {
        log.verbose(#function)
        let mutationsLoaded = DispatchSemaphore(value: 1)

        var resultFromQuery: Result<[MutationEvent], DataStoreError>?

        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            defer {
                mutationsLoaded.signal()
            }
            switch result {
            case .failure(let dataStoreError):
                resultFromQuery = .failure(dataStoreError)
            case .success(let mutationEvents):
                let sortedEvents = mutationEvents.sorted { $0.createdAt < $1.createdAt }
                resultFromQuery = .success(sortedEvents)
            }
        }

        mutationsLoaded.wait()

        // Should never happen, but guarding rather than force-unwrapping, just in case
        guard let result = resultFromQuery else {
            let dataStoreError = DataStoreError.unknown(
                "Return result unexpectedly nil querying mutation events",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
            )
            throw dataStoreError
        }

        switch result {
        case .failure(let dataStoreError):
            throw dataStoreError
        case .success(let mutationEvents):
            log.info("Loaded \(mutationEvents.count) previously saved mutation events")
            return mutationEvents
        }
    }

    func reset(onComplete: () -> Void) {
        storageAdapter = nil
        mutationEventSubject = nil
        onComplete()
    }

}

@available(iOS 13.0, *)
extension AWSMutationEventIngester: DefaultLogger { }
