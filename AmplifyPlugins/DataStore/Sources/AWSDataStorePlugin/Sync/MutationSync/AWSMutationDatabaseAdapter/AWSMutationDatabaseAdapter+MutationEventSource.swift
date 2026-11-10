//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSMutationDatabaseAdapter: MutationEventSource {

    /// DataStore implements a FIFO queue of MutationEvents by using the local database
    /// and querying for the earliest MutationEvent by its `createdAt` field.
    ///
    /// **Note**: In a previous revision of this code, this query used to filter on `InProcess` == `false` MutationEvents.
    /// This was to skip over already in-flight mutation events and grab the next one. However, it was observed in highly
    /// concurrent calls to `DataStore.start()` /`stop()` / `save()` that it will interrupt the
    /// **OutgoingMutationQueue** of processing and deleting a **MutationEvent** . `DataStore.start()`,
    /// which starts the remote sync engine, should perform a step to move all `InProcess` **MutationEvents** back
    /// to false, however there's a timing issue that is difficult to pinpoint. **OutgoingMutationQueue**'s query manages
    /// to pick up the second MutationEvent in the queue and sends it off, while the first one that is marked as `inProcess`
    /// isn't being processed, likely that process was already cancelled. The query below was updated to always dequeue the
    /// first regardless of `InProcess` in the [PR #3492](https://github.com/aws-amplify/amplify-swift/pull/3492).
    /// By removing the filter, there is a small chance that the same event may be sent twice. Sending the event twice is idempotent
    /// and the second response will be `ConditionalCheckFailed`. The `InProcess` flag is still needed for the
    /// handling consecutive update scenarios.
    ///
    /// Runs on `outboxQueue`, so it cannot interleave with an ingest.
    ///
    /// - Parameter completion: The first MutationEvent in the FIFO queue.
    func getNextMutationEvent(completion: @escaping DataStoreCallback<MutationEvent>) {
        log.verbose(#function)

        outboxQueue.async { [self] in
            // One request per subscription, so a parked one was superseded
            pendingRequest = nil
            guard let storageAdapter else {
                completion(.failure(DataStoreError.nilStorageAdapter()))
                return
            }

            switch await dequeueHead(storageAdapter: storageAdapter) {
            case .success(let mutationEvent?):
                completion(.success(mutationEvent))
            case .success(nil):
                pendingRequest = completion
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            }
        }
    }

    /// Delivers the head of the queue to a parked request. Call only on `outboxQueue`, after an ingest.
    func servePendingRequest(storageAdapter: StorageEngineAdapter) async {
        guard let request = pendingRequest else {
            return
        }
        pendingRequest = nil

        switch await dequeueHead(storageAdapter: storageAdapter) {
        case .success(let mutationEvent?):
            log.verbose("\(#function): delivering \(mutationEvent)")
            request(.success(mutationEvent))
        case .success(nil):
            pendingRequest = request
        case .failure(let dataStoreError):
            // Re-parked so the next write retries, instead of failing the outbox's subscription
            log.error("\(#function): failed to dequeue the next mutation event: \(dataStoreError)")
            pendingRequest = request
        }
    }

    /// Returns the head of the queue, marked in process, or `nil` if the queue is empty
    private func dequeueHead(storageAdapter: StorageEngineAdapter) async -> DataStoreResult<MutationEvent?> {
        let sort = QuerySortDescriptor(fieldName: MutationEvent.keys.createdAt.stringValue, order: .ascending)
        let queryResult = await withCheckedContinuation { continuation in
            storageAdapter.query(
                MutationEvent.self,
                predicate: nil,
                sort: [sort],
                paginationInput: nil,
                eagerLoad: true
            ) { result in
                continuation.resume(returning: result)
            }
        }

        let mutationEvent: MutationEvent
        switch queryResult {
        case .failure(let dataStoreError):
            return .failure(dataStoreError)
        case .success(let mutationEvents):
            guard let head = mutationEvents.first else {
                return .success(nil)
            }
            mutationEvent = head
        }

        if mutationEvent.inProcess {
            log.verbose("The head of the MutationEvent queue was already inProcess (most likely interrupted process): \(mutationEvent)")
            return .success(mutationEvent)
        }

        var inProcessEvent = mutationEvent
        inProcessEvent.inProcess = true
        let saveResult = await withCheckedContinuation { continuation in
            storageAdapter.save(inProcessEvent, condition: nil, eagerLoad: true) { result in
                continuation.resume(returning: result)
            }
        }
        return saveResult.map { $0 }
    }

}
