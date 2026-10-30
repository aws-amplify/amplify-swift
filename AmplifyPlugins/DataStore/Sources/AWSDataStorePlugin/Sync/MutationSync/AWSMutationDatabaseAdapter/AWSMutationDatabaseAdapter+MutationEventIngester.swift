//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSMutationDatabaseAdapter: MutationEventIngester {

    /// Accepts a mutation event without a version, applies the latest version from the MutationSyncMetadata table,
    /// writes the updated mutation event to the local database, then hands the queue's head to a parked outbox request
    func submit(mutationEvent: MutationEvent, completion: @escaping @Sendable (Result<MutationEvent, DataStoreError>) -> Void) {
        outboxQueue.async { [self] in
            log.verbose("\(#function): \(mutationEvent)")

            let result: DataStoreResult<MutationEvent>
            if let storageAdapter {
                result = await resolveConflictsThenSave(mutationEvent: mutationEvent, storageAdapter: storageAdapter)
                // Also after a failure: a save can commit its row and then fail to read it back
                await servePendingRequest(storageAdapter: storageAdapter)
            } else {
                result = .failure(DataStoreError.nilStorageAdapter())
            }

            // Off the queue, so the caller's work can't hold up the outbox
            Task { completion(result) }
        }
    }

    /// Resolves conflicts for the offered mutationEvent, and either accepts the event, returning a disposition, or
    /// rejects the event with an error
    private func resolveConflictsThenSave(
        mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) async -> DataStoreResult<MutationEvent> {
        let pendingResult = await withCheckedContinuation { continuation in
            MutationEvent.pendingMutationEvents(
                forMutationEvent: mutationEvent,
                storageAdapter: storageAdapter
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch pendingResult {
        case .failure(let dataStoreError):
            return .failure(dataStoreError)
        case .success(let localMutationEvents):
            let mutationDisposition = disposition(
                for: mutationEvent,
                given: localMutationEvents
            )
            return await resolve(
                candidate: mutationEvent,
                localEvents: localMutationEvents,
                per: mutationDisposition,
                storageAdapter: storageAdapter
            )
        }
    }

    func disposition(
        for candidate: MutationEvent,
        given localEvents: [MutationEvent]
    ) -> MutationDisposition {

        guard !localEvents.isEmpty, let existingEvent = localEvents.first else {
            log.verbose("\(#function) no local events, saving candidate")
            return .saveCandidate
        }

        if candidate.graphQLFilterJSON != nil {
            return .saveCandidate
        }

        guard let candidateMutationType = GraphQLMutationType(rawValue: candidate.mutationType) else {
            let dataStoreError =
                DataStoreError.unknown(
                    "Couldn't get mutation type for \(candidate.mutationType)",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
                )
            return .dropCandidateWithError(dataStoreError)
        }

        guard let existingMutationType = GraphQLMutationType(rawValue: existingEvent.mutationType) else {
            let dataStoreError =
                DataStoreError.unknown(
                    "Couldn't get mutation type for \(existingEvent.mutationType)",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
                )
            return .dropCandidateWithError(dataStoreError)
        }

        log.verbose("\(#function)(existing: \(existingMutationType), candidate: \(candidateMutationType))")

        switch (existingMutationType, candidateMutationType) {
        case (.create, .update),
             (.update, .update),
             (.update, .delete),
             (.delete, .delete):
            return .replaceLocalWithCandidate

        case (.create, .delete):
            return .dropCandidateAndDeleteLocal

        case (_, .create):
            let dataStoreError =
                DataStoreError.unknown(
                    "Received a create mutation for an item that has already been created",
                    """
                    Review your app code and ensure you are not issuing incorrect DataStore.save() calls for the same \
                    model. Candidate model is below:
                    \(candidate)
                    """
                )
            return .dropCandidateWithError(dataStoreError)

        case (.delete, .update):
            let dataStoreError =
                DataStoreError.unknown(
                    "Received an update mutation for an item that has been marked as deleted",
                    """
                    Review your app code and ensure you are not issuing incorrect DataStore.save() calls for the same \
                    model. Candidate model is below:
                    \(candidate)
                    """
                )
            return .dropCandidateWithError(dataStoreError)
        }

    }

    private func resolve(
        candidate: MutationEvent,
        localEvents: [MutationEvent],
        per disposition: MutationDisposition,
        storageAdapter: StorageEngineAdapter
    ) async -> DataStoreResult<MutationEvent> {
        log.verbose("\(#function) disposition \(disposition)")

        switch disposition {
        case .dropCandidateWithError(let dataStoreError):
            return .failure(dataStoreError)
        case .dropCandidateAndDeleteLocal:
            for localEvent in localEvents {
                let deleteResult = await withCheckedContinuation { continuation in
                    storageAdapter.delete(
                        untypedModelType: MutationEvent.self,
                        modelSchema: MutationEvent.schema,
                        withIdentifier: localEvent.identifier(schema: MutationEvent.schema),
                        condition: nil
                    ) { result in
                        continuation.resume(returning: result)
                    }
                }
                if case .failure(let dataStoreError) = deleteResult {
                    return .failure(dataStoreError)
                }
            }
            return .success(candidate)
        case .saveCandidate:
            return await save(mutationEvent: candidate, storageAdapter: storageAdapter)
        case .replaceLocalWithCandidate:
            guard !localEvents.isEmpty, let eventToUpdate = localEvents.first else {
                // Should be caught upstream, but being defensive
                return await save(mutationEvent: candidate, storageAdapter: storageAdapter)
            }

            if localEvents.count > 1 {
                // TODO: Handle errors from delete
                localEvents
                    .suffix(from: 1)
                    .forEach { storageAdapter.delete(
                        MutationEvent.self,
                        modelSchema: MutationEvent.schema,
                        withIdentifier: $0.identifier(schema: MutationEvent.schema),
                        condition: nil
                    ) { _ in } }
            }

            let resolvedEvent = getResolvedEvent(for: eventToUpdate, applying: candidate)

            return await save(mutationEvent: resolvedEvent, storageAdapter: storageAdapter)
        }
    }

    private func getResolvedEvent(
        for originalEvent: MutationEvent,
        applying candidate: MutationEvent
    ) -> MutationEvent {
        var resolvedEvent = originalEvent
        resolvedEvent.json = candidate.json

        let updatedMutationType: String = if candidate.mutationType == GraphQLMutationType.delete.rawValue {
            candidate.mutationType
        } else {
            originalEvent.mutationType
        }
        resolvedEvent.mutationType = updatedMutationType

        return resolvedEvent
    }

    /// Saves the deconflicted mutationEvent as resolved; serving the outbox is left to `submit`
    private func save(
        mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) async -> DataStoreResult<MutationEvent> {
        log.verbose("\(#function) mutationEvent: \(mutationEvent)")
        let result = await withCheckedContinuation { continuation in
            storageAdapter.save(mutationEvent, condition: nil, eagerLoad: true) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .failure(let dataStoreError):
            log.verbose("\(#function): Error saving mutation event: \(dataStoreError)")
        case .success(let savedMutationEvent):
            log.verbose("\(#function): saved \(savedMutationEvent)")
        }
        return result
    }

}
