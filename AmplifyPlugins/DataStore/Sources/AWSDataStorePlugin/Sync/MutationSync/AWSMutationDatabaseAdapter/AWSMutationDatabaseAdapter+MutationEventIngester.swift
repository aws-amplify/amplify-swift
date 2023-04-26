//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(OptionalExtension) import Amplify
import Combine
import Foundation

extension AWSMutationDatabaseAdapter: MutationEventIngester {

    /// Accepts a mutation event without a version, applies the latest version from the MutationSyncMetadata table,
    /// writes the updated mutation event to the local database, then submits it to `mutationEventSubject`
    func submit(mutationEvent: MutationEvent) -> Result<MutationEvent, DataStoreError> {
        log.verbose("\(#function): \(mutationEvent)")

        guard let storageAdapter = self.storageAdapter else {
            return .failure(DataStoreError.nilStorageAdapter())
        }

        return self.resolveConflictsThenSave(
            mutationEvent: mutationEvent,
            storageAdapter: storageAdapter
        )
    }

    /// Resolves conflicts for the offered mutationEvent, and either accepts the event, returning a disposition, or
    /// rejects the event with an error
    func resolveConflictsThenSave(
        mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) -> Result<MutationEvent, DataStoreError> {

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
            return .failure(DataStoreError(error: error))
        }

        return MutationEvent.pendingMutationEvents(
            forMutationEvent: mutationEvent,
            storageAdapter: storageAdapter
        ).flatMap { localMutationEvents in
            let mutationDisposition = self.disposition(for: mutationEvent, given: localMutationEvents)
            return self.resolve(
                candidate: mutationEvent,
                localEvents: localMutationEvents,
                per: mutationDisposition,
                storageAdapter: storageAdapter
            )
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

    func resolve(
        candidate: MutationEvent,
        localEvents: [MutationEvent],
        per disposition: MutationDisposition,
        storageAdapter: StorageEngineAdapter
    ) -> Result<MutationEvent, DataStoreError> {
        log.verbose("\(#function) disposition \(disposition)")

        switch disposition {
        case .dropCandidateWithError(let dataStoreError):
            return .failure(dataStoreError)
        case .dropCandidateAndDeleteLocal:
            let result: Result<Void, DataStoreError> = localEvents.reduce(.success(())) { partialResult, localEvent in
                partialResult.flatMap { _ in
                    storageAdapter.delete(
                        modelSchema: MutationEvent.schema,
                        withIdentifier: localEvent.identifier(schema: MutationEvent.schema),
                        condition: nil
                    ).dropSuccessValue()
                }
            }
            return result.map { _ in candidate}
        case .saveCandidate:
            return save(mutationEvent: candidate, storageAdapter: storageAdapter)
        case .replaceLocalWithCandidate:
            guard !localEvents.isEmpty, let eventToUpdate = localEvents.first else {
                // Should be caught upstream, but being defensive
                return save(mutationEvent: candidate, storageAdapter: storageAdapter)
            }

            // TODO: Handle errors from delete
            localEvents
                .dropFirst()
                .forEach {
                    _ = storageAdapter.delete(
                        modelSchema: MutationEvent.schema,
                        withIdentifier: $0.identifier(schema: MutationEvent.schema),
                        condition: nil)
                }

            let resolvedEvent = getResolvedEvent(for: eventToUpdate, applying: candidate)
            return save(mutationEvent: resolvedEvent, storageAdapter: storageAdapter)
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
    func save(
        mutationEvent: MutationEvent,
        storageAdapter: StorageEngineAdapter
    ) -> Result<MutationEvent, DataStoreError> {
        log.verbose("\(#function) mutationEvent: \(mutationEvent)")
        let nextEventPromise = self.nextEventPromise.getAndSet(nil)
        var eventToPersist = mutationEvent
        if nextEventPromise != nil {
            eventToPersist.inProcess = true
        }

        let result = storageAdapter.save(eventToPersist, modelSchema: eventToPersist.schema, condition: nil, eagerLoad: true)
        switch result {
        case .failure(let dataStoreError):
            self.log.verbose("\(#function): Error saving mutation event: \(dataStoreError)")
            // restore the `nextEventPromise` value when failed to save mutation event
            // as nextEventPromise is expecting to hanlde error of querying unprocessed mutaiton events
            // not the failure of saving mutaiton event operation
            nextEventPromise.ifSome(self.nextEventPromise.set(_:))
        case let .success((savedMutationEvent, _)):
            self.log.verbose("\(#function): saved \(savedMutationEvent)")
            nextEventPromise.ifSome {
                self.log.verbose("\(#function): invoking nextEventPromise with \(savedMutationEvent)")
                $0(.success(savedMutationEvent))
            }
        }

        self.log.verbose("\(#function): invoking completionPromise with \(result)")
        return result.map { $0.0 }
    }

}
