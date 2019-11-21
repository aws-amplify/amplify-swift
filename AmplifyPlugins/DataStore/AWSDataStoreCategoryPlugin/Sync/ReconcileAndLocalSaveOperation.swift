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
class ReconcileAndLocalSaveOperation<M: Model>: Operation {
    typealias LocalModel = M
    typealias CloudModel = M
    typealias SavedModel = M

    /// States are descriptive, they say what is happening in the system right now
    enum State {
        case waiting
        case deserializing(AnyModel, CloudModel.Type)
        case querying(CloudModel)
        case reconciling(CloudModel, LocalModel?)
        case saving(CloudModel)
        case notifying(SavedModel)

        // Terminal states
        case finished
        case inError(AmplifyError)
    }

    /// Actions are declarative, they say what I just did
    enum Action {
        case started(AnyModel, CloudModel.Type)
        case deserialized(CloudModel)
        case queried(CloudModel, LocalModel?)
        case reconciled(CloudModel)
        case cancelled
        case conflicted(CloudModel, LocalModel)
        case saved(SavedModel)
        case notified
        case errored(AmplifyError)
    }

    private weak var storageAdapter: StorageEngineAdapter?
    let stateMachine: StateMachine<State, Action>
    let anyModel: AnyModel
    let modelType: M.Type
    var stateMachineSink: AnyCancellable?

    init(anyModel: AnyModel,
         modelType: M.Type,
         storageAdapter: StorageEngineAdapter) {
        self.anyModel = anyModel
        self.modelType = modelType
        self.storageAdapter = storageAdapter
        self.stateMachine = StateMachine(initialState: .waiting,
                                         resolver: ReconcileAndLocalSaveOperation.resolve(currentState:action:))
        super.init()
    }

    override func main() {
        guard !isCancelled else {
            return
        }

        stateMachineSink = stateMachine
            .$state
            .sink { [weak self] in
                self?.log.verbose("New state: \($0)")
                self?.respond(to: $0)
        }

        stateMachine.notify(action: .started(anyModel, modelType))
    }

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    func respond(to newState: State) {
        switch newState {
        case .waiting:
            break

        case .deserializing(let anyModel, let modelType):
            deserialize(anyModel: anyModel, into: modelType)

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
    func deserialize(anyModel: AnyModel, into modelType: M.Type) {
        guard !isCancelled else {
            return
        }

        guard let model = anyModel.instance as? M else {
            let dataStoreError = DataStoreError.decodingError(
                "Cannot extract \(modelType) from AnyModel",
                """
                Ensure the incoming, type-erased AnyModel matches the expected type, \(modelType). The AnyModel is \
                below:
                \(anyModel)
                """
            )
            let errorAction = Action.errored(dataStoreError)
            stateMachine.notify(action: errorAction)
            return
        }

        let action = Action.deserialized(model)
        stateMachine.notify(action: action)
    }

    /// Responder method for `querying`. Notify actions:
    /// - queried
    /// - errored
    func query(cloudModel: CloudModel) {
        guard !isCancelled else {
            return
        }

        Amplify.Logging.log.verbose("Querying model: \(cloudModel.id)")

        guard let storageAdapter = storageAdapter else {
            Amplify.Logging.log.warn("No storageAdapter, aborting")
            return
        }

        let predicate: QueryPredicateFactory = { field("id") == cloudModel.id }

        storageAdapter.query(type(of: cloudModel), predicate: predicate()) { queryResult in
            let models: [LocalModel]
            switch queryResult {
            case .error(let dataStoreError):
                self.stateMachine.notify(action: .errored(dataStoreError))
                return
            case .result(let result):
                models = result
            }

            guard !models.isEmpty else {
                let emptyQueriedAction = Action.queried(cloudModel, nil)
                self.stateMachine.notify(action: emptyQueriedAction)
                return
            }

            guard models.count == 1 else {
                let dataStoreError = DataStoreError.nonUniqueResult(model: cloudModel.modelName)
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
                return
            }

            // We know models has exactly one element, so force-unwrapping is OK here
            let localModel = models.first!

            let queriedAction = Action.queried(cloudModel, localModel)
            self.stateMachine.notify(action: queriedAction)
        }
    }

    /// Responder method for `reconciling`. Notify actions:
    /// - reconciled
    /// - conflict
    /// - errored
    func reconcile(cloudModel: CloudModel, to localModel: LocalModel?) {
        guard !isCancelled else {
            return
        }

        guard let localModel = localModel else {
            let reconciledAction = Action.reconciled(cloudModel)
            stateMachine.notify(action: reconciledAction)
            return
        }

        // TODO: Reenable this once we add version/conflict state to DataStore system
        let reconciledAction = Action.reconciled(cloudModel)
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
        guard !isCancelled else {
            return
        }

        guard let storageAdapter = storageAdapter else {
            Amplify.Logging.log.warn("No storageAdapter, aborting")
            return
        }

        storageAdapter.save(cloudModel) { response in
            switch response {
            case .error(let dataStoreError):
                let errorAction = Action.errored(dataStoreError)
                self.stateMachine.notify(action: errorAction)
            case .result(let savedModel):
                self.stateMachine.notify(action: .saved(savedModel))
            }
        }
    }

    /// Responder method for `notifying`. Notify actions:
    /// - notified
    func notify(savedModel: SavedModel) {
        guard !isCancelled else {
            return
        }

        // TODO: Create a sync notification payload of <M>
        let payload = HubPayload(eventName: "SYNC_HAPPENED, YAY! \(savedModel.id)")
        Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        stateMachine.notify(action: .notified)
    }

    // MARK: - Resolver

    /// It's not absolutely required to make `resolve` a static, but it helps in two ways:
    /// 1. It makes it easier to avoid retain cycles, since the reducer can't close over the state machine's owning
    ///    instance
    /// 2. It helps enforce "pure function" behavior since `resolve` can only make decisions about the current state
    ///    and the action, rather than peeking out to some other state of the instance.
    static func resolve(currentState: State, action: Action) -> State {
        switch (currentState, action) {

        case (.waiting, .started(let anyModel, let modelType)):
            return .deserializing(anyModel, modelType)

        case (.deserializing, .deserialized(let model)):
            return .querying(model)

        case (.querying, .queried(let cloudModel, let localModel)):
            return .reconciling(cloudModel, localModel)

        case (.reconciling, .reconciled(let cloudModel)):
            return .saving(cloudModel)

        case (.saving, .saved(let savedModel)):
            return .notifying(savedModel)

        case (_, .errored(let amplifyError)):
            return .inError(amplifyError)

        case (.notifying, .notified):
            return .finished

        case (.finished, _):
            return .finished

        default:
            log.warn("Unexpected state transition. In \(currentState), got \(action)")
            return currentState
        }

    }

}

extension ReconcileAndLocalSaveOperation: SelfLogging { }
