//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

extension AWSMutationDatabaseAdapter: MutationEventIngester {

    /// Accepts a mutation event without a version, applies the latest version from the MutationSyncMetadata table,
    /// writes the updated mutation event to the local database, then submits it to `mutationEventSubject`
    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        log.verbose("\(#function): \(mutationEvent)")

        return Future<MutationEvent, DataStoreError> {
            guard let storageAdapter = self.storageAdapter else {
                throw DataStoreError.nilStorageAdapter()
            }

            let result = await self.resolveConflictsThenSave(mutationEvent: mutationEvent,
                                                             storageAdapter: storageAdapter)
            switch result {
            case .success(let mutationEvents):
                return mutationEvents
            case .failure(let error):
                throw error
            }
        }
    }

    /// Resolves conflicts for the offered mutationEvent, and either accepts the event, returning a disposition, or
    /// rejects the event with an error
    func resolveConflictsThenSave(mutationEvent: MutationEvent,
                                  storageAdapter: StorageEngineAdapter) async -> DataStoreResult<MutationEvent> {
        // We don't want to query MutationSync<AnyModel> because a) we already have the model, and b) delete mutations
        // are submitted *after* the delete has already been applied to the local data store, meaning there is no model
        // to query.
        var mutationEvent = mutationEvent
        do {
            // TODO: Refactor this so that it's clear that the storage engine is not responsible for setting the version
            // perhaps as simple as renaming to `submit(unversionedMutationEvent:)` or similar
            let syncMetadata = try storageAdapter.queryMutationSyncMetadata(for: mutationEvent.modelId,
                                                                               modelName: mutationEvent.modelName)
            mutationEvent.version = syncMetadata?.version
        } catch {
            return .failure(causedBy: error)
        }

        let result = await MutationEvent.pendingMutationEvents(for: mutationEvent.modelId, storageAdapter: storageAdapter)
        
        switch result {
        case .failure(let dataStoreError):
            return .failure(dataStoreError)
        case .success(let localMutationEvents):
            let mutationDisposition = self.disposition(for: mutationEvent,
                                                       given: localMutationEvents)
            return await resolve(candidate: mutationEvent,
                                 localEvents: localMutationEvents,
                                 per: mutationDisposition,
                                 storageAdapter: storageAdapter)
        }
    }

    func disposition(for candidate: MutationEvent,
                     given localEvents: [MutationEvent]) -> MutationDisposition {

        guard !localEvents.isEmpty, let existingEvent = localEvents.first else {
            log.verbose("\(#function) no local events, saving candidate")
            return .saveCandidate
        }

        if candidate.graphQLFilterJSON != nil {
            return .saveCandidate
        }

        guard let candidateMutationType = GraphQLMutationType(rawValue: candidate.mutationType) else {
            let dataStoreError =
                DataStoreError.unknown("Couldn't get mutation type for \(candidate.mutationType)",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
            return .dropCandidateWithError(dataStoreError)
        }

        guard let existingMutationType = GraphQLMutationType(rawValue: existingEvent.mutationType) else {
            let dataStoreError =
                DataStoreError.unknown("Couldn't get mutation type for \(existingEvent.mutationType)",
                    AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
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

    func resolve(candidate: MutationEvent,
                 localEvents: [MutationEvent],
                 per disposition: MutationDisposition,
                 storageAdapter: StorageEngineAdapter) async -> DataStoreResult<MutationEvent> {
        self.log.verbose("\(#function) disposition \(disposition)")

        switch disposition {
        case .dropCandidateWithError(let dataStoreError):
            return .failure(dataStoreError)
        case .dropCandidateAndDeleteLocal:
            // TODO: Handle errors from delete, and convert to async
            let group = DispatchGroup()
            localEvents.forEach {
                group.enter()
                storageAdapter.delete(MutationEvent.self,
                                      modelSchema: MutationEvent.schema,
                                      withId: $0.id,
                                      condition: nil) { _ in group.leave() }
            }
            group.wait()
            return .success(candidate)
        case .saveCandidate:
            return await save(mutationEvent: candidate,
                              storageAdapter: storageAdapter)
        case .replaceLocalWithCandidate:
            guard !localEvents.isEmpty, let eventToUpdate = localEvents.first else {
                // Should be caught upstream, but being defensive
                return await save(mutationEvent: candidate,
                                  storageAdapter: storageAdapter)
            }

            if localEvents.count > 1 {
                // TODO: Handle errors from delete
                localEvents
                    .suffix(from: 1)
                    .forEach { storageAdapter.delete(MutationEvent.self,
                                                     modelSchema: MutationEvent.schema,
                                                     withId: $0.id,
                                                     condition: nil) { _ in } }
            }

            let resolvedEvent = getResolvedEvent(for: eventToUpdate, applying: candidate)

            return await save(mutationEvent: resolvedEvent,
                              storageAdapter: storageAdapter)
        }
        
    }

    private func getResolvedEvent(for originalEvent: MutationEvent,
                                  applying candidate: MutationEvent) -> MutationEvent {
        var resolvedEvent = originalEvent
        resolvedEvent.json = candidate.json

        let updatedMutationType: String
        if candidate.mutationType == GraphQLMutationType.delete.rawValue {
            updatedMutationType = candidate.mutationType
        } else {
            updatedMutationType = originalEvent.mutationType
        }
        resolvedEvent.mutationType = updatedMutationType

        resolvedEvent.version = candidate.version

        return resolvedEvent
    }

    /// Saves the deconflicted mutationEvent, invokes `nextEventPromise` if it exists, and the save was successful,
    /// and finally invokes the completion promise from the future of the original invocation of `submit`
    func save(mutationEvent: MutationEvent,
              storageAdapter: StorageEngineAdapter) async -> DataStoreResult<MutationEvent> {
        log.verbose("\(#function) mutationEvent: \(mutationEvent)")
        var eventToPersist = mutationEvent
        if self.nextEventPromise.get() != nil {
            eventToPersist.inProcess = true
        }
        let result = await storageAdapter.save(eventToPersist, condition: nil)
        switch result {
        case .failure(let dataStoreError):
            self.log.verbose("\(#function): Error saving mutation event: \(dataStoreError)")
        case .success(let savedMutationEvent):
            self.log.verbose("\(#function): saved \(savedMutationEvent)")
            if let nextEventPromise = self.nextEventPromise.getAndSet(nil) {
                self.log.verbose("\(#function): invoking nextEventPromise with \(savedMutationEvent)")
                nextEventPromise(.success(savedMutationEvent))
            }
        }
        log.verbose("\(#function): invoking completionPromise with \(result)")
        return result
    }

}
