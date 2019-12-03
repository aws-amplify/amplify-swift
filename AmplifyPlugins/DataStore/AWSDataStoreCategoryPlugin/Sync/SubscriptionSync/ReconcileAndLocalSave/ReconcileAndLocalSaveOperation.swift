//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// Reconciles an incoming model mutation with the stored model. If there is no conflict (e.g., the incoming model has
/// a later version than the stored model), then write the new data to the store.
@available(iOS 13.0, *)
class ReconcileAndLocalSaveOperation: Operation {
    typealias LocalModel = Model
    typealias CloudModel = Model
    typealias SavedModel = Model

    private let workQueue = DispatchQueue(label: "com.amazonaws.ReconcileAndLocalSaveOperation",
                                          target: DispatchQueue.global())

    private weak var storageAdapter: StorageEngineAdapter?
    private let stateMachine: StateMachine<State, Action>
    private let anyModel: AnyModel
    private var stateMachineSink: AnyCancellable?

    init(anyModel: AnyModel,
         storageAdapter: StorageEngineAdapter,
         stateMachine: StateMachine<State, Action>? = nil) {
        self.anyModel = anyModel
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

        stateMachine.notify(action: .started(anyModel))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .waiting:
            break

        case .deserializing(let anyModel):
            deserialize(anyModel: anyModel)

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

    /// Responder method for `deserializing`. Notify actions:
    /// - deserialized
    /// - error
    func deserialize(anyModel: AnyModel) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        let action = Action.deserialized(anyModel.instance)
        stateMachine.notify(action: action)
    }

    /// Responder method for `querying`. Notify actions:
    /// - queried
    /// - errored
    func query(cloudModel: CloudModel) {
        log.verbose("query: \(cloudModel)")
        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        guard let storageAdapter = storageAdapter else {
            Amplify.Logging.log.warn("No storageAdapter, aborting")
            return
        }

        guard let modelType = ModelRegistry.modelType(from: cloudModel.modelName) else {
            Amplify.Logging.log.warn("No model for \(cloudModel.modelName), aborting")
            return
        }

        let predicate: QueryPredicateFactory = { field("id") == cloudModel.id }

        storageAdapter.query(untypedModel: modelType, predicate: predicate()) { queryResult in
            let models: [LocalModel]
            switch queryResult {
            case .failure(let dataStoreError):
                self.stateMachine.notify(action: .errored(dataStoreError))
                return
            case .success(let result):
                models = result
            }

            guard !models.isEmpty else {
                let emptyQueriedAction = Action.queried(cloudModel, nil)
                self.stateMachine.notify(action: emptyQueriedAction)
                return
            }

            guard let localModel = models.first, models.count == 1 else {
                let dataStoreError = DataStoreError.nonUniqueResult(model: cloudModel.modelName, count: models.count)
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
                return
            }

            let queriedAction = Action.queried(cloudModel, localModel)
            self.stateMachine.notify(action: queriedAction)
        }
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

        guard let localModel = localModel else {
            log.verbose("\(#function) - saving new model")
            let reconciledAction = Action.reconciled(cloudModel)
            stateMachine.notify(action: reconciledAction)
            return
        }

        // TODO: Reenable this once we add version/conflict state to DataStore system
        let reconciledAction = Action.reconciled(cloudModel)
        log.verbose("\(#function) - Cloud model newer than local model, saving")
        stateMachine.notify(action: reconciledAction)
//        if cloudModel.version > localModel.version {
//            let reconciledAction = Action.reconciled(cloudModel)
//            stateMachine.notify(action: reconciledAction)
//        } else if cloudModel.version < localModel.version {
//            let conflictAction = Actions.conflicted(cloudModel, localModel)
//            stateMachine.notify(action: conflictAction)
//        } else {
//            let duplicateEventAction = ???
//            stateMachine.notify(action: duplicateEventAction)
//        }
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

        storageAdapter.save(untypedModel: cloudModel) { response in
            self.log.verbose("\(#function) - response: \(response)")
            switch response {
            case .failure(let dataStoreError):
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .success(let savedModel):
                self.stateMachine.notify(action: .saved(savedModel))
            }
        }
    }

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: SavedModel) {
        log.verbose(#function)

        guard !isCancelled else {
            log.verbose("\(#function) - cancelled, aborting")
            return
        }

        // TODO: Dispatch/notify error if we can't erase to any model? Would imply an error in JSON decoding,
        // which shouldn't be possible this late in the process. Possibly notify global conflict/error handler?
        guard let anyModel = try? savedModel.eraseToAnyModel() else {
            log.error("Could not notify mutatione vent")
            return
        }

        // TODO: Get the mutationType
        let mutationEvent = try! MutationEvent(model: anyModel, mutationType: .create)
        
        let payload = HubPayload(eventName: HubPayload.EventName.DataStore.syncReceived,
                                 data: anyModel)
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)

        // TODO: Add publisher
        // publisher?.send(input: mutationEvent)

        stateMachine.notify(action: .notified)
    }

}

@available(iOS 13.0, *)
extension ReconcileAndLocalSaveOperation: DefaultLogger { }
