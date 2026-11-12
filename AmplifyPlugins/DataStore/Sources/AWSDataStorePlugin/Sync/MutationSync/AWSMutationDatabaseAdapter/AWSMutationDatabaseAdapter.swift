//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Interface for saving and loading MutationEvents from storage
/// - Note: `@unchecked Sendable`: `pendingRequest` and every read-modify-write of the MutationEvent table made here
///   run on `outboxQueue`; `storageAdapter` is a weak reference written only by init and `reset()`, and each block
///   copies it once.
final class AWSMutationDatabaseAdapter: @unchecked Sendable {
    /// Possible outcomes of a "submit" based on inspecting the locally stored MutationEvents
    enum MutationDisposition {
        /// Drops the candidate without saving
        case dropCandidateWithError(DataStoreError)

        /// Enqueues the candidate event as a new entry in the queue
        case saveCandidate

        /// Replace all existing mutation events with the one candidate
        case replaceLocalWithCandidate

        /// Happens if the queue has a .create and the incoming event is a .delete
        case dropCandidateAndDeleteLocal
    }

    weak var storageAdapter: StorageEngineAdapter?

    /// Runs each ingest and each dequeue to completion, one at a time
    let outboxQueue = TaskQueue<Void>()

    /// The outbox's request, parked when it found the queue empty. Only touched on `outboxQueue`
    var pendingRequest: DataStoreCallback<MutationEvent>?

    /// Holds a weak reference to the storage adapter the outbox reads and writes
    init(storageAdapter: StorageEngineAdapter) throws {
        self.storageAdapter = storageAdapter
        log.verbose("Initialized")
    }

}

extension AWSMutationDatabaseAdapter: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName, forNamespace: String(describing: self))
    }
    var log: Logger {
        Self.log
    }
}

extension AWSMutationDatabaseAdapter: Resettable {

    func reset() async {
        log.verbose("Resetting AWSMutationDatabaseAdapter")
        storageAdapter = nil
        // Enqueued, not awaited, so a stalled block can't hold up reset
        outboxQueue.async { self.pendingRequest = nil }
        log.verbose("Resetting AWSMutationDatabaseAdapter: finished")
    }

}
