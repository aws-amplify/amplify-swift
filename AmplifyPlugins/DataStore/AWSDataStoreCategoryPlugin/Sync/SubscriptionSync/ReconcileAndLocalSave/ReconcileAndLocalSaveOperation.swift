//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    private let workQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndLocalSaveOperation",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?
    private let stateMachine: StateMachine<State, Action>
    private let remoteModel: RemoteModel
    private var stateMachineSink: AnyCancellable?

    private let mutationEventPublisher: PassthroughSubject<ReconcileAndLocalSaveOperationEvent, DataStoreError>
    public var publisher: AnyPublisher<ReconcileAndLocalSaveOperationEvent, DataStoreError> {
        return mutationEventPublisher.eraseToAnyPublisher()
    }

    init(remoteModel: RemoteModel,
         storageAdapter: StorageEngineAdapter?,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.remoteModel = remoteModel
        self.storageAdapter = storageAdapter
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

        stateMachine.notify(action: .started(remoteModel))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .querying(let remoteModel):
            query(remoteModel: remoteModel)

        case .reconciling(let remoteModel, let localMetadata):
            reconcile(remoteModel: remoteModel, to: localMetadata)

        case .executing(let disposition):
            execute(disposition: disposition)

        case .notifyingDropped(let modelName):
            notifyDropped(modelName: modelName)

        case .notifying(let savedModel, let existsLocally):
            notify(savedModel: savedModel, existsLocally: existsLocally)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)
            notifyFinished()
            finish()

        case .finished:
            // Maybe we have to notify the Hub?
            notifyFinished()
            finish()
        }

    }

    // MARK: - Responder methods

    /// Responder method for `querying`. Notify actions:
    /// - queried
    /// - errored
    func query(remoteModel: RemoteModel) {
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
        } catch {
            stateMachine.notify(action: .errored(DataStoreError(error: error)))
            return
        }

        let queriedAction = Action.queried(remoteModel, localMetadata)
        stateMachine.notify(action: queriedAction)
    }

    /// Responder method for `reconciling`. Notify actions:
    /// - reconciled
    /// - conflict
    /// - errored
    func reconcile(remoteModel: RemoteModel, to localMetadata: LocalMetadata?) {
        log.verbose(#function)
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        let pendingMutations: [MutationEvent]
        switch getPendingMutations(forModelId: remoteModel.model.id) {
        case .failure(let dataStoreError):
            stateMachine.notify(action: .errored(dataStoreError))
            return
        case .success(let mutationEvents):
            pendingMutations = mutationEvents
        }

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localMetadata,
                                                         pendingMutations: pendingMutations)

        stateMachine.notify(action: .reconciled(disposition))
    }

    /// Responder method for `executing`. Applies the appropriate disposition. Either invokes `apply`, or directly
    /// notifies the state machine for:
    /// - errored
    /// - dropped
    func execute(disposition: RemoteSyncReconciler.Disposition) {
        switch disposition {
        case .applyRemoteModel(let remoteModel):
            apply(remoteModel: remoteModel)
        case .dropRemoteModel(let modelName):
            stateMachine.notify(action: .dropped(modelName: modelName))
        case .error(let dataStoreError):
            stateMachine.notify(action: .errored(dataStoreError))
        }
    }

    /// Execution method for the `applyRemoteModel` disposition. Does not notify directly, but delegates to save or
    /// delete methods, which eventually notify with:
    /// - applied
    /// - errored
    private func apply(remoteModel: RemoteModel) {
        if log.logLevel == .verbose {
            log.verbose("\(#function): remoteModel")
        } else if log.logLevel == .debug {
            log.debug(#function)
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
        if remoteModel.syncMetadata.deleted {
            saveDeleteMutation(storageAdapter: storageAdapter, remoteModel: remoteModel)
        } else {
            saveCreateOrUpdateMutation(storageAdapter: storageAdapter, remoteModel: remoteModel)
        }

    }

    private func saveDeleteMutation(storageAdapter: StorageEngineAdapter, remoteModel: RemoteModel) {
        log.verbose(#function)
        guard let modelType = ModelRegistry.modelType(from: remoteModel.model.modelName) else {
            let error = DataStoreError.invalidModelName(remoteModel.model.modelName)
            stateMachine.notify(action: .errored(error))
            return
        }

        storageAdapter.delete(untypedModelType: modelType, withId: remoteModel.model.id) { response in
            switch response {
            case .failure(let dataStoreError):
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success:
                self.saveMetadata(storageAdapter: storageAdapter, inProcessModel: remoteModel)
            }
        }
    }

    private func saveCreateOrUpdateMutation(storageAdapter: StorageEngineAdapter, remoteModel: RemoteModel) {
        log.verbose(#function)
        storageAdapter.save(untypedModel: remoteModel.model.instance) { response in
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
                self.saveMetadata(storageAdapter: storageAdapter, inProcessModel: inProcessModel)
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              inProcessModel: AppliedModel) {
        log.verbose(#function)

        /// Do a local metadata query before saving to check if the `AppliedModel` is of `create` or
        /// `update` MutationType from the perspective of the local store
        let existsLocally: Bool
        do {
            let localMetadata = try storageAdapter.queryMutationSyncMetadata(for: remoteModel.model.id)
            existsLocally = localMetadata != nil
        } catch {
            log.error("Failed to query for sync metadata")
            return
        }
        storageAdapter.save(remoteModel.syncMetadata, condition: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success(let syncMetadata):
                let appliedModel = MutationSync(model: inProcessModel.model, syncMetadata: syncMetadata)
                self.stateMachine.notify(action: .applied(appliedModel, existsLocally: existsLocally))
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
                existsLocally: Bool) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        let mutationType: MutationEvent.MutationType
        let version = savedModel.syncMetadata.version
        if savedModel.syncMetadata.deleted {
            mutationType = .delete
        } else if !existsLocally {
            mutationType = .create
        } else {
            mutationType = .update
        }

        // TODO: Dispatch/notify error if we can't erase to any model? Would imply an error in JSON decoding,
        // which shouldn't be possible this late in the process. Possibly notify global conflict/error handler?
        guard let mutationEvent = try? MutationEvent(untypedModel: savedModel.model.instance,
                                                     mutationType: mutationType,
                                                     version: version)
            else {
                log.error("Could not notify mutation event")
                return
        }

        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncReceived,
                                 data: mutationEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)

        mutationEventPublisher.send(.mutationEvent(mutationEvent))

        stateMachine.notify(action: .notified)
    }

    private func notifyFinished() {
        mutationEventPublisher.send(completion: .finished)
    }

    private func getPendingMutations(forModelId modelId: Model.Identifier) -> DataStoreResult<[MutationEvent]> {
        guard let storageAdapter = storageAdapter else {
            return .failure(DataStoreError.nilStorageAdapter())
        }

        let semaphore = DispatchSemaphore(value: 0)
        var pendingMutationResultFromQuery: DataStoreResult<[MutationEvent]>?
        MutationEvent.pendingMutationEvents(forModelId: modelId,
                                            storageAdapter: storageAdapter) {
                                                pendingMutationResultFromQuery = $0
                                                semaphore.signal()
        }
        semaphore.wait()

        guard let pendingMutationResult = pendingMutationResultFromQuery else {
            let dataStoreError = DataStoreError.unknown("Unable to query pending mutation events",
                                                        AmplifyErrorMessages.shouldNotHappenReportBugToAWS())
            return .failure(dataStoreError)
        }

        return pendingMutationResult
    }

}

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }

enum ReconcileAndLocalSaveOperationEvent {
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String)
}
