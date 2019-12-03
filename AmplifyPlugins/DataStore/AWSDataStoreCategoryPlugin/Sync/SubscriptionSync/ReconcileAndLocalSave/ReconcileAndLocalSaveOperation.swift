//
// Copyright 2018-2019 Amazon.com,
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
class ReconcileAndLocalSaveOperation: Operation {
    typealias LocalModel = MutationSync<AnyModel>
    typealias CloudModel = MutationSync<AnyModel>
    typealias SavedModel = MutationSync<AnyModel>

    private let workQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndLocalSaveOperation",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?
    private let stateMachine: StateMachine<State, Action>
    private let cloudModel: CloudModel
    private var stateMachineSink: AnyCancellable?

    init(cloudModel: CloudModel,
         storageAdapter: StorageEngineAdapter,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.cloudModel = cloudModel
        self.storageAdapter = storageAdapter
        self.stateMachine = stateMachine ?? StateMachine(initialState: .waiting,
                                                         resolver: Resolver.resolve(currentState:action:))
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

        stateMachine.notify(action: .started(cloudModel))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .deserializing(let cloudModel):
            deserialize(cloudModel: cloudModel)

        case .querying(let cloudModel):
            query(cloudModel: cloudModel)

        case .reconciling(let cloudModel, let localModel):
            reconcile(cloudModel: cloudModel, to: localModel)

        case .saving(let cloudModel):
            save(cloudModel: cloudModel)

        case .notifying(let savedModel):
            notify(savedModel: savedModel)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .finished:
            // Maybe we have to notify the Hub?
            break
        }

    }

    // MARK: - Responder methods

    // TODO: Remove this; we get a CloudModel (MutationSync<AnyModel>) from the subscription
    /// Responder method for `deserializing`. Notify actions:
    /// - deserialized
    /// - error
    func deserialize(cloudModel: CloudModel) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        let action = Action.deserialized(cloudModel)
        stateMachine.notify(action: action)
    }

    /// Responder method for `querying`. Notify actions:
    /// - queried
    /// - errored
    func query(cloudModel: CloudModel) {
        log.verbose("query: \(cloudModel)")
        guard !isCancelled else {
            log.info("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.notify(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        let localModel: MutationSync<AnyModel>?
        do {
            localModel = try storageAdapter.queryMutationSync(forAnyModel: cloudModel.model)
        } catch {
            stateMachine.notify(action: .errored(DataStoreError(error: error)))
            return
        }

        let queriedAction = Action.queried(cloudModel, localModel)
        stateMachine.notify(action: queriedAction)
    }

    /// Responder method for `reconciling`. Notify actions:
    /// - reconciled
    /// - conflict
    /// - errored
    func reconcile(cloudModel: CloudModel, to localModel: LocalModel?) {
        log.verbose(#function)
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            stateMachine.notify(action: .errored(DataStoreError.nilStorageAdapter()))
            return
        }

        let reconciler = RemoteSyncReconciler(cloudModel: cloudModel,
                                              to: localModel,
                                              storageAdapter: storageAdapter)

        let disposition = reconciler.reconcile()

        let reconciledAction = Action.reconciled(cloudModel)
        log.verbose("\(#function) - Cloud model newer than local model, saving")
        stateMachine.notify(action: reconciledAction)

    }

    /// Responder method for `save`. Notify actions:
    /// - saved
    /// - errored
    func save(cloudModel: CloudModel) {
        if log.logLevel == .verbose {
            log.verbose("\(#function): cloudModel")
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
        let anyModel = cloudModel.model
        let syncMetadata = cloudModel.syncMetadata

        log.verbose("Saving cloud model")
        storageAdapter.save(untypedModel: anyModel.instance) { response in
            self.log.verbose("\(#function) - response: \(response)")
            switch response {
            case .failure(let dataStoreError):
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success(let savedModel):
                // TODO: move this into a separate call when we get transaction support in DataStore
                let anyModel: AnyModel
                do {
                    anyModel = try savedModel.eraseToAnyModel()
                } catch {
                    self.stateMachine.notify(action: .errored(DataStoreError(error: error)))
                    return
                }

                storageAdapter.save(syncMetadata) { result in
                    switch result {
                    case .failure(let dataStoreError):
                        let errorAction = Action.errored(dataStoreError)
                        self.stateMachine.notify(action: errorAction)
                    case .success(let syncMetadata):
                        let mutationSync = MutationSync(model: anyModel, syncMetadata: syncMetadata)
                        self.stateMachine.notify(action: .saved(mutationSync))
                    }
                }
            }
        }

        log.verbose("Saving cloud syncMetadata")

    }

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: SavedModel) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        let mutationType: MutationEvent.MutationType
        let version = savedModel.syncMetadata.version
        if savedModel.syncMetadata.deleted {
            mutationType = .delete
        } else if version == 1 {
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

        // TODO: Add publisher
        // publisher?.send(input: mutationEvent)

        stateMachine.notify(action: .notified)
    }

}

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }
