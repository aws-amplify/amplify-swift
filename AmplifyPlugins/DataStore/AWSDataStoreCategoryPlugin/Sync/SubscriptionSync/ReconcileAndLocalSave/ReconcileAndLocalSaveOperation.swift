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
         storageAdapter: StorageEngineAdapter?,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.modelSchema = modelSchema
        self.remoteModel = remoteModel
        self.storageAdapter = storageAdapter
        self.stopwatch = Stopwatch()
        self.stateMachine = stateMachine ?? StateMachine(initialState: .waiting,
                                                         resolver: Resolver.resolve(currentState:action:))
        self.mutationEventPublisher = PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>()

        super.init()

        self.stateMachineSink = self.stateMachine
            .$state
            .sink { [weak self] newState in
                guard let self = self else {
                    return
                }
                self.log.verbose("New state: \(newState)")
                self.workQueue.async {
                    self.respond(to: newState)
                }
        }
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            return
        }

        stopwatch.start()
        stateMachine.notify(action: .started(remoteModel))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .queryingPendingMutations(let remoteModel):
            queryPendingMutations(remoteModel: remoteModel)

        case .reconcilingWithPendingMutations(let remoteModel, let pendingMutations):
            reconcile(remoteModel, pendingMutations: pendingMutations)

        case .queryingLocalMetadata(let remoteModel):
            queryLocalMetadata(remoteModel: remoteModel)

        case .reconcilingWithLocalMetadata(let remoteModel, let localMetadata):
            reconcile(remoteModel, localMetadata: localMetadata)

        case .applyingRemoteModel(let remoteModel, let mutationType):
            applyRemoteModel(remoteModel: remoteModel, mutationType: mutationType)

        case .notifyingDropped(let modelName):
            notifyDropped(modelName: modelName)

        case .notifying(let savedModel, let mutationType):
            notify(savedModel: savedModel, mutationType: mutationType)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)
            notifyFinished()
            finish()

        case .finished:
            // Maybe we have to notify the Hub?
            notifyFinished()
            if log.logLevel == .debug {
                log.debug("total time: \(stopwatch.stop())s")
            }
            finish()
        }

    }

    // MARK: - Responder methods

    func queryPendingMutations(remoteModel: RemoteModel) {
        log.verbose(#function)
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.notify(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        MutationEvent.pendingMutationEvents(forModelId: remoteModel.model.id,
                                            storageAdapter: storageAdapter) { result in
            if log.logLevel == .debug {
                log.debug("query pending mutations: \(stopwatch.lap())s")
            }

            switch result {
            case .failure(let dataStoreError):
                stateMachine.notify(action: .errored(dataStoreError))
                return
            case .success(let mutationEvents):
                stateMachine.notify(action: .queriedPendingMutations(remoteModel, mutationEvents))
            }
        }
    }

    func reconcile(_ remoteModel: RemoteModel, pendingMutations: [MutationEvent]) {
        if let remoteModelToApply = RemoteSyncReconciler.reoncile(remoteModel,
                                                                  pendingMutations: pendingMutations) {
            stateMachine.notify(action: .reconciledWithPendingMutations(remoteModelToApply))
        } else {
            stateMachine.notify(action: .dropped(modelName: remoteModel.model.modelName))
        }
    }

    func queryLocalMetadata(remoteModel: RemoteModel) {
        log.verbose("query: \(remoteModel)")
        guard !isCancelled else {
            log.info("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.notify(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        let localMetadata: MutationSyncMetadata?
        do {
            localMetadata = try storageAdapter.queryMutationSyncMetadata(for: remoteModel.model.id)
            if log.logLevel == .debug {
                log.debug("query local metadata: \(stopwatch.lap())s")
            }
        } catch {
            stateMachine.notify(action: .errored(DataStoreError(error: error)))
            return
        }
        stateMachine.notify(action: .queriedLocalMetadata(remoteModel, localMetadata))
    }

    func reconcile(_ remoteModel: RemoteModel, localMetadata: MutationSyncMetadata?) {
        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                                   to: localMetadata)
        switch disposition {
        case .applyRemoteModel(let remoteModel, let mutationType):
            stateMachine.notify(action: .reconciledAsApply(remoteModel, mutationType))
        case .dropRemoteModel(let modelName):
            stateMachine.notify(action: .dropped(modelName: modelName))
        }
    }

    func applyRemoteModel(remoteModel: RemoteModel, mutationType: MutationEvent.MutationType) {
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

        // TODO: Wrap this in a transaction
        if mutationType == .delete {
            saveDeleteMutation(storageAdapter: storageAdapter, remoteModel: remoteModel)
        } else {
            saveCreateOrUpdateMutation(storageAdapter: storageAdapter,
                                       remoteModel: remoteModel,
                                       mutationType: mutationType)
        }
    }

    private func saveDeleteMutation(storageAdapter: StorageEngineAdapter,
                                    remoteModel: RemoteModel) {
        log.verbose(#function)

        guard let modelType = ModelRegistry.modelType(from: modelSchema.name) else {
            let error = DataStoreError.invalidModelName(modelSchema.name)
            stateMachine.notify(action: .errored(error))
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
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success:
                self.saveMetadata(storageAdapter: storageAdapter,
                                  inProcessModel: remoteModel,
                                  mutationType: .delete)
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
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success(let savedModel):
                let anyModel: AnyModel
                do {
                    anyModel = try savedModel.eraseToAnyModel()
                } catch {
                    self.stateMachine.notify(action: .errored(DataStoreError(error: error)))
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
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success(let syncMetadata):
                let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                self.stateMachine.notify(action: .applied(appliedModel, mutationType))
            }
        }
    }

    func notifyDropped(modelName: String) {
        mutationEventPublisher.send(.mutationEventDropped(modelName: modelName))
        stateMachine.notify(action: .notified)
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

        stateMachine.notify(action: .notified)
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
