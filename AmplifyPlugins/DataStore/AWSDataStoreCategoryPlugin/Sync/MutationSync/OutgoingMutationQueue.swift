//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

@available(iOS 13.0, *)
final class OutgoingMutationQueue {
    private typealias SavedMutationEvent = MutationEvent
    private typealias SavedEventPromise = Future<MutationEvent, DataStoreError>.Promise

    /// States are descriptive, they say what is happening in the system right now
    private enum State {
        // Startup/config states
        case notInitialized
        case loadingSavedMutations
        case enqueuingInitialOperations([MutationEvent])

        // Event processing loop
        case waiting
        case saving(MutationEvent, SavedEventPromise)
        case enqueuing(SavedMutationEvent)

        // Terminal states
        case finished
        case inError(AmplifyError)
    }

    /// Actions are declarative, they say what I just did
    private enum Action {
        // Startup/config actions
        case initialized
        case loadedSavedMutations([MutationEvent])
        case enqueuedInitialOperations

        // Event processing loop
        case receivedEvent(MutationEvent, SavedEventPromise)
        case saved(SavedMutationEvent)
        case enqueued(SavedMutationEvent)

        // Terminal actions
        case receivedCancel
        case errored(AmplifyError)
    }

    private let stateMachine: StateMachine<State, Action>
    private var stateMachineSink: AnyCancellable?

    private let operationQueue: OperationQueue

    private let workQueue = DispatchQueue(label: "com.amazonaws.OutgoingMutationOperationQueue",
                                          target: DispatchQueue.global())

    private weak var syncEngine: CloudSyncEngineBehavior?
    private weak var storageAdapter: StorageEngineAdapter?
    private weak var api: APICategoryGraphQLBehavior?

    init(storageAdapter: StorageEngineAdapter) {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.OutgoingMutationOperationQueue"
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true

        self.operationQueue = operationQueue

        // TODO: Find the right place to do this
        ModelRegistry.register(modelType: MutationEvent.self)

        self.stateMachine = StateMachine(initialState: .notInitialized,
                                         resolver: OutgoingMutationQueue.resolve(currentState:action:))

        self.stateMachineSink = stateMachine
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

        stateMachine.notify(action: .initialized)
    }

    // MARK: - Public API

    func startSyncingToCloud(syncEngine: CloudSyncEngineBehavior, api: APICategoryGraphQLBehavior) {
        self.syncEngine = syncEngine
        self.api = api
        operationQueue.isSuspended = false
    }

    func cancel() {
        operationQueue.cancelAllOperations()
        stateMachine.notify(action: .receivedCancel)
    }

    func pauseSyncingToCloud() {
        operationQueue.isSuspended = true
    }

    func submit(mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        // Promise to be delivered to the fulfillment method. The future containing the promise will be returned to
        // the caller for subsequent fulfillment.
        var promise: SavedEventPromise!
        let future = Future<MutationEvent, DataStoreError> { promiseFromFutureBody in
            promise = promiseFromFutureBody
        }
        stateMachine.notify(action: .receivedEvent(mutationEvent, promise))
        return future
    }

    // MARK: - Responders

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .loadingSavedMutations:
            loadSavedMutations()

        case .enqueuingInitialOperations(let mutationEvents):
            enqueueInitialOperations(mutationEvents: mutationEvents)

        case .saving(let mutationEvent, let promise):
            save(mutationEvent: mutationEvent, completionPromise: promise)

        case .enqueuing(let savedMutationEvent):
            enqueue(savedMutationEvent: savedMutationEvent)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .notInitialized,
             .waiting,
             .finished:
            break
        }

    }

    /// Responder method for `loadingSavedMutations`. Notify actions
    /// - errored
    /// - loadedSavedMutations
    private func loadSavedMutations() {
        guard let storageAdapter = storageAdapter else {
            stateMachine.notify(action: .errored(Errors.nilStorageAdapter))
            return
        }

        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                self.stateMachine.notify(action: .errored(dataStoreError))
            case .success(let mutationEvents):
                self.stateMachine.notify(action: .loadedSavedMutations(mutationEvents))
            }
        }
    }

    /// Responder method for `enqueuingInitialOperations`. Notify actions
    /// - errored
    /// - enqueuedInitialOperations
    private func enqueueInitialOperations(mutationEvents: [MutationEvent]) {
        guard let api = api else {
            stateMachine.notify(action: .errored(Errors.nilAPIBehavior))
            return
        }

        for mutationEvent in mutationEvents {
            let syncMutationToCloudOperation =
                SyncMutationToCloudOperation(mutationEvent: mutationEvent, api: api)

            operationQueue.addOperation(syncMutationToCloudOperation)
        }

        stateMachine.notify(action: .enqueuedInitialOperations)
    }

    /// Responder method for `saving`. In addition to notifying the state machine for internal state tracking, this
    /// method invokes the promise completion based on the outcome of the save. Notify actions:
    /// - errored
    /// - saved
    private func save(mutationEvent: MutationEvent, completionPromise: @escaping SavedEventPromise) {
        guard let storageAdapter = storageAdapter else {
            completionPromise(.failure(Errors.nilStorageAdapter))
            stateMachine.notify(action: .errored(Errors.nilStorageAdapter))
            return
        }

        storageAdapter.save(mutationEvent) {
            switch $0 {
            case .failure(let dataStoreError):
                completionPromise(.failure(dataStoreError))
                self.stateMachine.notify(action: .errored(dataStoreError))
            case .success(let savedMutationEvent):
                completionPromise(.success(savedMutationEvent))
                self.stateMachine.notify(action: .saved(savedMutationEvent))
            }
        }
    }

    /// Responder method for `enqueue`. Notify actions:
    /// - errored
    /// - enqueued
    private func enqueue(savedMutationEvent: SavedMutationEvent) {
        guard let api = api else {
            stateMachine.notify(action: .errored(Errors.nilAPIBehavior))
            return
        }

        let syncMutationToCloudOperation =
            SyncMutationToCloudOperation(mutationEvent: savedMutationEvent, api: api)

        operationQueue.addOperation(syncMutationToCloudOperation)
    }

    // MARK: - Resolver

    private static func resolve(currentState: State, action: Action) -> State {
        switch (currentState, action) {

        case (.notInitialized, .initialized):
            return .loadingSavedMutations

        case (.loadingSavedMutations, .loadedSavedMutations(let mutationEvents)):
            return .enqueuingInitialOperations(mutationEvents)

        case (.enqueuingInitialOperations, .enqueuedInitialOperations):
            return .waiting

        case (.waiting, .receivedEvent(let mutationEvent, let promise)):
            return .saving(mutationEvent, promise)

        case (.saving, .saved(let savedMutationEvent)):
            return .enqueuing(savedMutationEvent)

        case (.enqueuing, .enqueued):
            return .waiting

        case (_, .errored(let amplifyError)):
            return .inError(amplifyError)

        case (_, .receivedCancel):
            return .finished

        case (.finished, _):
            return .finished

        default:
            log.warn("Unexpected state transition. In \(currentState), got \(action)")
            return currentState
        }

    }

}

extension OutgoingMutationQueue: DefaultLogger { }
