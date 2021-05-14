//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

/// Reconciles an incoming model mutation with the stored model. If there is no conflict (e.g., the incoming model has
/// a later version than the stored model), then write the new data to the store.
@available(iOS 13.0, *)
class ReconcileAndLocalSaveOperation: AsynchronousOperation {

    /// Disambiguation for the version of the model incoming from the remote API
    typealias RemoteModel = MutationSync<AnyModel>

    /// Disambiguation for the sync metadata for the model stored in local datastore
    typealias LocalMetadata = MutationSyncMetadata

    /// Disambiguation for the version of the model that was applied to the local datastore. In the case of a create or
    /// update mutation, this represents the saved model. In the case of a delete mutation, this is the data that was
    /// sent from the remote API as part of the mutation.
    typealias AppliedModel = MutationSync<AnyModel>

    let id: UUID = UUID()
    private let workQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndLocalSaveOperation",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?
    private let stateMachine: StateMachine<State, Action>
    private let remoteModels: [RemoteModel]
    private let modelSchema: ModelSchema
    private let stopwatch: Stopwatch
    private var stateMachineSink: AnyCancellable?

    private let mutationEventPublisher: PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>
    public var publisher: AnyPublisher<ReconcileAndLocalSaveOperationEvent, DataStoreError> {
        return mutationEventPublisher.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         remoteModels: [RemoteModel],
         storageAdapter: StorageEngineAdapter?,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.modelSchema = modelSchema
        self.remoteModels = remoteModels
        self.storageAdapter = storageAdapter
        self.stopwatch = Stopwatch()

        self.mutationEventPublisher = PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>()
        self.stateMachine = stateMachine ?? StateMachine(initialState: .waiting,
                                                         resolver: Resolver.resolve(currentState:action:))
        super.init()

        self.stateMachine.responder = responder
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.respond(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        stopwatch.start()
        do {
            try storageAdapter.transaction {
                stateMachine.respond(action: .started(remoteModels))
            }
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            stateMachine.respond(action: .errored(dataStoreError))
        }
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func responder(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .queryingPendingMutations(let remoteModels):
            queryPendingMutations(remoteModels: remoteModels)

        case .reconcilingWithPendingMutations(let remoteModels, let pendingMutations):
            reconcile(remoteModels, pendingMutations: pendingMutations)

        case .queryingLocalMetadata(let remoteModels):
            queryLocalMetadata(remoteModels: remoteModels)

        case .reconcilingWithLocalMetadata(let remoteModel, let localMetadatas):
            reconcile(remoteModel, localMetadatas: localMetadatas)

        case .applyingRemoteModels(let disposition):
            applyRemoteModels(disposition: disposition)

        case .notifyingDropped(let modelName):
            notifyDropped(modelName: modelName)

        case .notifying(let savedModel, let mutationType):
            notify(savedModel: savedModel, mutationType: mutationType)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)
            notifyFinished()

        case .finished:
            // Maybe we have to notify the Hub?
            if log.logLevel == .debug {
                log.debug("total time: \(stopwatch.stop())s")
            }
            notifyFinished()
        }

    }

    // MARK: - Responder methods

    func queryPendingMutations(remoteModels: [RemoteModel]) {
        log.verbose(#function)
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.respond(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        guard !remoteModels.isEmpty else {
            // TODO state transition what which action? "finished"
            notifyFinished()
            return
        }
        let remoteModelIds = remoteModels.map { remoteModel in
            remoteModel.model.id
        }

        MutationEvent.pendingMutationEvents(forModelIds: remoteModelIds,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let dataStoreError):
                stateMachine.respond(action: .errored(dataStoreError))
                return
            case .success(let mutationEvents):
                stateMachine.respond(action: .queriedPendingMutations(remoteModels, mutationEvents))
            }
        }
    }

    func reconcile(_ remoteModels: [RemoteModel], pendingMutations: [MutationEvent]) {
        guard let remoteModel = remoteModels.first else {
            notifyFinished()
            return
        }

        let remoteModelsToApply = RemoteSyncReconciler.reconcile(remoteModels,
                                                                 pendingMutations: pendingMutations)

        for _ in 0 ..< (remoteModels.count - remoteModelsToApply.count) {
            mutationEventPublisher.send(.mutationEventDropped(modelName: remoteModel.model.modelName))
        }

        stateMachine.respond(action: .reconciledWithPendingMutations(remoteModelsToApply))
    }

    func queryLocalMetadata(remoteModels: [RemoteModel]) {
        guard !isCancelled else {
            log.info("\(#function) - cancelled, aborting")
            return
        }

        guard let remoteModel = remoteModels.first else {
            notifyFinished()
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.respond(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        var localMetadatas = [LocalMetadata]()
        let remoteModelIds = remoteModels.map { remoteModel in
            remoteModel.model.id
        }
        let maxNumberOfPredicates = 950
        let chunkedModelIdsArr = remoteModelIds.chunked(into: maxNumberOfPredicates)
        do {
            for chunkedModelIds in chunkedModelIdsArr {
                localMetadatas.append(
                    contentsOf: try storageAdapter.queryMutationSyncMetadata(forModelIds: chunkedModelIds))
            }
        } catch {
            stateMachine.respond(action: .errored(DataStoreError(error: error)))
            return
        }

        stateMachine.respond(action: .queriedLocalMetadata(remoteModels, localMetadatas))
    }

    func reconcile(_ remoteModels: [RemoteModel], localMetadatas: [LocalMetadata]) {
        guard let remoteModel = remoteModels.first else {
            notifyFinished()
            return
        }

        let disposition = RemoteSyncReconciler.reconcile(remoteModels: remoteModels,
                                                         localMetadatas: localMetadatas)
        for _ in 0 ..< (remoteModels.count - disposition.totalCount) {
            mutationEventPublisher.send(.mutationEventDropped(modelName: remoteModel.model.modelName))
        }

        stateMachine.respond(action: .reconciledAsApply(disposition))
    }

    func applyRemoteModels(disposition: RemoteSyncReconciler.Disposition) {
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            Amplify.Logging.log.warn("No storageAdapter, aborting")
            return
        }

        let count = AtomicValue<Int>(initialValue: disposition.totalCount)
        let saveMetadataCompletionBlock: DataStoreCallback<Void> = { result in
            switch result {
            case .success:
                if count.decrement() == 0 {
                    self.stateMachine.respond(action: .notified)
                }
            case .failure(let error):
                self.stateMachine.respond(action: .errored(error))
            }
        }
        let onSaveMutation: DataStoreCallback<(RemoteModel, MutationEvent.MutationType)> = { result in
            switch result {
            case .success((let remoteModel, let mutationType)):
                self.saveMetadata(storageAdapter: storageAdapter,
                                  inProcessModel: remoteModel,
                                  mutationType: mutationType,
                                  completion: saveMetadataCompletionBlock)
            case .failure(let error):
                self.stateMachine.respond(action: .errored(error))
            }
        }
        for deleteModel in disposition.deleteModels {
            saveDeleteMutation(storageAdapter: storageAdapter,
                               remoteModel: deleteModel,
                               completion: onSaveMutation)
        }
        for createModel in disposition.createModels {
            saveCreateOrUpdateMutation(storageAdapter: storageAdapter,
                                       remoteModel: createModel,
                                       mutationType: .create,
                                       completion: onSaveMutation)
        }
        for updateModel in disposition.updateModels {
            saveCreateOrUpdateMutation(storageAdapter: storageAdapter,
                                       remoteModel: updateModel,
                                       mutationType: .update,
                                       completion: onSaveMutation)
        }
    }

    private func saveDeleteMutation(storageAdapter: StorageEngineAdapter,
                                    remoteModel: RemoteModel,
                                    completion: @escaping
                                        DataStoreCallback<(RemoteModel, MutationEvent.MutationType)>) {
        log.verbose(#function)

        guard let modelType = ModelRegistry.modelType(from: modelSchema.name) else {
            let error = DataStoreError.invalidModelName(modelSchema.name)
            stateMachine.respond(action: .errored(error))
            return
        }

        storageAdapter.delete(untypedModelType: modelType,
                              modelSchema: modelSchema,
                              withId: remoteModel.model.id,
                              predicate: nil) { response in
            if log.logLevel == .debug {
                log.debug("delete model: \(stopwatch.lap())s")
            }
            switch response {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success:
                completion(.success((remoteModel, .delete)))

            }
        }
    }

    private func saveCreateOrUpdateMutation(storageAdapter: StorageEngineAdapter,
                                            remoteModel: RemoteModel,
                                            mutationType: MutationEvent.MutationType,
                                            completion: @escaping
                                                DataStoreCallback<(RemoteModel, MutationEvent.MutationType)>) {
        log.verbose(#function)
        storageAdapter.save(untypedModel: remoteModel.model.instance) { response in
            switch response {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let savedModel):
                let anyModel: AnyModel
                do {
                    anyModel = try savedModel.eraseToAnyModel()
                } catch {
                    let dataStoreError = DataStoreError(error: error)
                    completion(.failure(dataStoreError))
                    return
                }
                let inProcessModel = MutationSync(model: anyModel, syncMetadata: remoteModel.syncMetadata)
                completion(.success((inProcessModel, mutationType)))
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              inProcessModel: AppliedModel,
                              mutationType: MutationEvent.MutationType,
                              completion: @escaping DataStoreCallback<Void>) {
        storageAdapter.save(inProcessModel.syncMetadata, condition: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let syncMetadata):
                let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                self.notify(savedModel: appliedModel, mutationType: mutationType, completion: completion)
            }
        }
    }

    func notifyDropped(modelName: String) {
        mutationEventPublisher.send(.mutationEventDropped(modelName: modelName))
        stateMachine.respond(action: .notified)
    }

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: AppliedModel,
                mutationType: MutationEvent.MutationType,
                completion: DataStoreCallback<Void> = { _ in }) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }
        let version = savedModel.syncMetadata.version

        // TODO: Dispatch/notify error if we can't erase to any model? Would imply an error in JSON decoding,
        // which shouldn't be possible this late in the process. Possibly notify global conflict/error handler?
        guard let json = try? savedModel.model.instance.toJSON() else {
            log.error("Could not notify mutation event")
            return
        }
        let mutationEvent = MutationEvent(modelId: savedModel.model.instance.id,
                                          modelName: modelSchema.name,
                                          json: json,
                                          mutationType: mutationType,
                                          version: version)

        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncReceived,
                                 data: mutationEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)

        mutationEventPublisher.send(.mutationEvent(mutationEvent))

        //stateMachine.notify(action: .notified)
        completion(.successfulVoid)
    }

    private func notifyFinished() {
        mutationEventPublisher.send(completion: .finished)
        finish()
    }
}

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }

enum ReconcileAndLocalSaveOperationEvent {
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String)
}
