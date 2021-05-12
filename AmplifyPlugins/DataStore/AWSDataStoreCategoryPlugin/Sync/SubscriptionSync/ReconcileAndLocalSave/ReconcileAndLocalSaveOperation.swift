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
         storageAdapter: StorageEngineAdapter?) {
        self.modelSchema = modelSchema
        self.remoteModels = remoteModels
        self.storageAdapter = storageAdapter
        self.stopwatch = Stopwatch()
        self.mutationEventPublisher = PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>()

        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            return
        }

        stopwatch.start()

        guard let storageAdapter = storageAdapter else {
            finishWithError(DataStoreError.nilStorageAdapter())
            return
        }

        do {
            try storageAdapter.transaction {
                reconcileAndSave()
            }
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            finishWithError(dataStoreError)
        }
    }

    func reconcileAndSave() {
        guard !remoteModels.isEmpty else {
            finishWithNotify()
            return
        }
        let onRemoteModelsApplied: DataStoreCallback<Void> = { result in
            switch result {
            case .success:
                self.finishWithNotify()
            case .failure(let error):
                self.finishWithError(error)
            }
        }
        let onRemoteModelsDisposition: DataStoreCallback<RemoteSyncReconciler.Disposition> = { result in
            switch result {
            case .success(let disposition):
                guard disposition.totalCount > 0 else {
                    self.finishWithNotify()
                    return
                }
                self.applyRemoteModels(disposition, completion: onRemoteModelsApplied)
            case .failure(let error):
                self.finishWithError(error)
            }
        }
        let onRemoteModelsToApply: DataStoreCallback<[RemoteModel]> = { result in
            switch result {
            case .success(let remoteModelsToApply):
                guard !remoteModelsToApply.isEmpty else {
                    self.finishWithNotify()
                    return
                }

                self.reoncileAgainstLocalMetadatas(remoteModels: remoteModelsToApply,
                                                   completion: onRemoteModelsDisposition)
            case .failure(let error):
                self.finishWithError(error)
            }
        }

        reconcileAgainstPendingMutations(remoteModels: remoteModels,
                                         completion: onRemoteModelsToApply)
    }

    func reconcileAgainstPendingMutations(remoteModels: [RemoteModel], completion: DataStoreCallback<[RemoteModel]>) {
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }
        guard let storageAdapter = storageAdapter else {
            completion(.failure(DataStoreError.nilStorageAdapter()))
            return
        }
        guard let remoteModel = remoteModels.first else {
            completion(.success(remoteModels))
            return
        }

        let remoteModelIds = remoteModels.map { remoteModel in
            remoteModel.model.id
        }

        MutationEvent.pendingMutationEvents(forModelIds: remoteModelIds,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
                return
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty else {
                    completion(.success(remoteModels))
                    return
                }

                let remoteModelsToApply = RemoteSyncReconciler.reconcile(remoteModels,
                                                                         pendingMutations: mutationEvents)
                for _ in 0 ..< (remoteModels.count - remoteModelsToApply.count) {
                    mutationEventPublisher.send(.mutationEventDropped(modelName: remoteModel.model.modelName))
                }

                completion(.success(remoteModelsToApply))
            }
        }
    }

    func reoncileAgainstLocalMetadatas(remoteModels: [RemoteModel],
                                       completion: DataStoreCallback<RemoteSyncReconciler.Disposition>) {
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }
        guard let storageAdapter = storageAdapter else {
            completion(.failure(DataStoreError.nilStorageAdapter()))
            return
        }
        guard let remoteModel = remoteModels.first else {
            completion(.success(RemoteSyncReconciler.Disposition()))
            return
        }

        var localMetadatas = [MutationSyncMetadata]()
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
            completion(.failure(DataStoreError(error: error)))
            return
        }

        let disposition = RemoteSyncReconciler.reconcile(remoteModels: remoteModels,
                                                         localMetadatas: localMetadatas)
        for _ in 0 ..< (remoteModels.count - disposition.totalCount) {
            mutationEventPublisher.send(.mutationEventDropped(modelName: remoteModel.model.modelName))
        }
        completion(.success(disposition))
    }

    func applyRemoteModels(_ disposition: RemoteSyncReconciler.Disposition,
                           completion: @escaping DataStoreCallback<Void>) {
        log.verbose(#function)
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
                    completion(.successfulVoid)
                }
            case .failure(let error):
                completion(.failure(error))
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
                completion(.failure(error))
            }
        }
        for deleteModel in disposition.deleteModels {
            saveDeleteMutation(storageAdapter: storageAdapter,
                               remoteModel: deleteModel,
                               mutationType: .delete,
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
                                    mutationType: MutationEvent.MutationType,
                                    completion: DataStoreCallback<(RemoteModel, MutationEvent.MutationType)>) {
        guard let modelType = ModelRegistry.modelType(from: modelSchema.name) else {
            let error = DataStoreError.invalidModelName(modelSchema.name)
            completion(.failure(error))
            return
        }

        storageAdapter.delete(untypedModelType: modelType,
                              modelSchema: modelSchema,
                              withId: remoteModel.model.id,
                              predicate: nil) { response in

            switch response {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success:
                completion(.success((remoteModel, mutationType)))
            }
        }
    }

    private func saveCreateOrUpdateMutation(storageAdapter: StorageEngineAdapter,
                                            remoteModel: RemoteModel,
                                            mutationType: MutationEvent.MutationType,
                                            completion: @escaping
                                                DataStoreCallback<(RemoteModel, MutationEvent.MutationType)>) {
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

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: AppliedModel,
                mutationType: MutationEvent.MutationType,
                completion: DataStoreCallback<Void>) {
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

        completion(.successfulVoid)
    }

    func finishWithError(_ error: AmplifyError) {
        // Maybe we have to notify the Hub?
        log.error(error: error)
        notifyFinished()
        finish()
    }

    func finishWithNotify() {
        // Maybe we have to notify the Hub?
        notifyFinished()
        if log.logLevel == .debug {
            log.debug("total time: \(stopwatch.stop())s")
        }
        finish()
    }

    private func notifyFinished() {
        mutationEventPublisher.send(completion: .finished)
    }
}

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }

enum ReconcileAndLocalSaveOperationEvent {
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String)
}
