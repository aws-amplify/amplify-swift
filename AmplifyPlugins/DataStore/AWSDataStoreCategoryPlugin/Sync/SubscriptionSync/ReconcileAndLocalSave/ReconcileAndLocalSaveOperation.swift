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
    private let remoteModel: RemoteModel
    private let modelSchema: ModelSchema
    private let stopwatch: Stopwatch
    private var stateMachineSink: AnyCancellable?

    private let mutationEventPublisher: PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>
    public var publisher: AnyPublisher<ReconcileAndLocalSaveOperationEvent, DataStoreError> {
        return mutationEventPublisher.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         remoteModel: RemoteModel,
         storageAdapter: StorageEngineAdapter?) {
        self.modelSchema = modelSchema
        self.remoteModel = remoteModel
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
        queryPendingMutations(remoteModel: remoteModel)
    }

    // MARK: - Responder methods

    func queryPendingMutations(remoteModel: RemoteModel) {
        log.verbose(#function)
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            finishWithError(DataStoreError.nilStorageAdapter())
            return
        }

        MutationEvent.pendingMutationEvents(forModelId: remoteModel.model.id,
                                            storageAdapter: storageAdapter) { result in
            if log.logLevel == .debug {
                log.debug("query pending mutations: \(stopwatch.lap())s")
            }

            switch result {
            case .failure(let dataStoreError):
                finishWithError(dataStoreError)
                return
            case .success(let mutationEvents):
                if RemoteSyncReconciler.shouldDropRemoteModel(remoteModel,
                                                              pendingMutations: mutationEvents) {
                    notifyDropped(modelName: remoteModel.model.modelName)
                } else {
                    queryLocalMetadata(remoteModel: remoteModel)
                }
            }
        }
    }

    func queryLocalMetadata(remoteModel: RemoteModel) {
        log.verbose("query: \(remoteModel)")
        guard !isCancelled else {
            log.info("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            finishWithError(DataStoreError.nilStorageAdapter())
            return
        }

        let localMetadata: MutationSyncMetadata?
        do {
            localMetadata = try storageAdapter.queryMutationSyncMetadata(for: remoteModel.model.id)
            if log.logLevel == .debug {
                log.debug("query local metadata: \(stopwatch.lap())s")
            }
        } catch {
            finishWithError(DataStoreError(error: error))
            return
        }

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                                   to: localMetadata)

        switch disposition {
        case .applyRemoteModel(let remoteModel, let mutationType):
            applyRemoteModel(remoteModel: remoteModel, mutationType: mutationType)
        case .dropRemoteModel(let modelName):
            notifyDropped(modelName: modelName)
        }

    }

    /// Execution method for the `applyRemoteModel` disposition. Does not notify directly, but delegates to save or
    /// delete methods, which eventually notify with:
    /// - applied
    /// - errored
    func applyRemoteModel(remoteModel: RemoteModel,
                          mutationType: MutationEvent.MutationType) {
        if log.logLevel == .verbose {
            log.verbose("\(#function): remoteModel")
        }

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            Amplify.Logging.log.warn("No storageAdapter, aborting")
            return
        }

        if mutationType == .delete {
            saveDeleteMutation(storageAdapter: storageAdapter,
                               remoteModel: remoteModel,
                               mutationType: mutationType)
        } else {
            saveCreateOrUpdateMutation(storageAdapter: storageAdapter,
                                       remoteModel: remoteModel,
                                       mutationType: mutationType)
        }
    }

    private func saveDeleteMutation(storageAdapter: StorageEngineAdapter,
                                    remoteModel: RemoteModel,
                                    mutationType: MutationEvent.MutationType) {
        log.verbose(#function)

        guard let modelType = ModelRegistry.modelType(from: modelSchema.name) else {
            let error = DataStoreError.invalidModelName(modelSchema.name)
            finishWithError(error)
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
                finishWithError(dataStoreError)
            case .success:
                self.saveMetadata(storageAdapter: storageAdapter,
                                  inProcessModel: remoteModel,
                                  mutationType: mutationType)
            }
        }
    }

    private func saveCreateOrUpdateMutation(storageAdapter: StorageEngineAdapter,
                                            remoteModel: RemoteModel,
                                            mutationType: MutationEvent.MutationType) {
        log.verbose(#function)
        storageAdapter.save(untypedModel: remoteModel.model.instance) { response in
            if self.log.logLevel == .debug {
                self.log.debug("save model: \(self.stopwatch.lap())s")
            }
            switch response {
            case .failure(let dataStoreError):
                self.finishWithError(dataStoreError)
            case .success(let savedModel):
                let anyModel: AnyModel
                do {
                    anyModel = try savedModel.eraseToAnyModel()
                } catch {
                    let dataStoreError = DataStoreError(error: error)
                    self.finishWithError(dataStoreError)
                    return
                }
                let inProcessModel = MutationSync(model: anyModel, syncMetadata: remoteModel.syncMetadata)
                self.saveMetadata(storageAdapter: storageAdapter,
                                  inProcessModel: inProcessModel,
                                  mutationType: mutationType)
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              inProcessModel: AppliedModel,
                              mutationType: MutationEvent.MutationType) {
        log.verbose(#function)

        storageAdapter.save(remoteModel.syncMetadata, condition: nil) { result in
            if self.log.logLevel == .debug {
                self.log.debug("save metadata: \(self.stopwatch.lap())s")
            }
            switch result {
            case .failure(let dataStoreError):
                self.finishWithError(dataStoreError)
            case .success(let syncMetadata):
                let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                self.notify(savedModel: appliedModel, mutationType: mutationType)
            }
        }
    }

    func notifyDropped(modelName: String) {
        mutationEventPublisher.send(.mutationEventDropped(modelName: modelName))
        finishWithNotify()
    }

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: AppliedModel,
                mutationType: MutationEvent.MutationType) {
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

        finishWithNotify()
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
