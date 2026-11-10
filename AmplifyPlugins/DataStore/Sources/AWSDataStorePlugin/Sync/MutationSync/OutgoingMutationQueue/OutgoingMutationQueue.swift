//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@preconcurrency import AWSPluginsCore
import Combine
import Foundation

/// Submits outgoing mutation events to the provisioned API
protocol OutgoingMutationQueueBehavior: AnyObject {
    func stopSyncingToCloud(_ completion: @escaping BasicClosure)
    func startSyncingToCloud(
        api: APICategoryGraphQLBehavior,
        mutationEventPublisher: MutationEventPublisher,
        reconciliationQueue: IncomingEventReconciliationQueue?
    )
    var publisher: AnyPublisher<MutationEvent, Never> { get }
}

/// - Note: `@unchecked Sendable`: the queue's state transitions all run on its own serial
///   `DispatchQueue`.
final class OutgoingMutationQueue: OutgoingMutationQueueBehavior, @unchecked Sendable {

    private let stateMachine: StateMachine<State, Action>
    private var stateMachineSink: AnyCancellable?

    private let operationQueue: OperationQueue

    /// A DispatchQueue for synchronizing state on the mutation queue
    private let mutationDispatchQueue = TaskQueue<Void>()

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?

    private var subscription: Subscription?
    private let dataStoreConfiguration: DataStoreConfiguration
    private let storageAdapter: StorageEngineAdapter
    private var authModeStrategy: AuthModeStrategy

    private let outgoingMutationQueueSubject: PassthroughSubject<MutationEvent, Never>
    var publisher: AnyPublisher<MutationEvent, Never> {
        return outgoingMutationQueueSubject.eraseToAnyPublisher()
    }

    /// Bumped on every stop, so work begun before it can tell it is stale.
    private let sessionGeneration = AtomicValue(initialValue: 0)
    /// The session that requested the event in flight, recorded on `mutationDispatchQueue` like `doStop`.
    private let requestedGeneration = AtomicValue(initialValue: 0)

    init(
        _ stateMachine: StateMachine<State, Action>? = nil,
        storageAdapter: StorageEngineAdapter,
        dataStoreConfiguration: DataStoreConfiguration,
        authModeStrategy: AuthModeStrategy
    ) {
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        self.authModeStrategy = authModeStrategy

        let operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.OutgoingMutationOperationQueue"
        operationQueue.qualityOfService = .default
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true

        self.operationQueue = operationQueue

        self.stateMachine = stateMachine ??
            StateMachine(
                initialState: .notInitialized,
                resolver: OutgoingMutationQueue.Resolver.resolve(currentState:action:)
            )

        self.outgoingMutationQueueSubject = PassthroughSubject<MutationEvent, Never>()

        self.stateMachineSink = self.stateMachine
            .$state
            .sink { [weak self] newState in
                guard let self else { return }

                log.verbose("New state: \(newState)")
                mutationDispatchQueue.async {
                    self.respond(to: newState)
                }
        }

        log.verbose("Initialized")
        self.stateMachine.notify(action: .initialized)
    }

    // MARK: - Public API

    func startSyncingToCloud(
        api: APICategoryGraphQLBehavior,
        mutationEventPublisher: MutationEventPublisher,
        reconciliationQueue: IncomingEventReconciliationQueue?
    ) {
        log.verbose(#function)
        stateMachine.notify(action: .receivedStart(api, mutationEventPublisher, reconciliationQueue))
    }

    func stopSyncingToCloud(_ completion: @escaping BasicClosure) {
        log.verbose(#function)
        stateMachine.notify(action: .receivedStop(completion))
    }

    // MARK: - Responders

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {

        case .starting(let api, let mutationEventPublisher, let reconciliationQueue):
            doStart(api: api, mutationEventPublisher: mutationEventPublisher, reconciliationQueue: reconciliationQueue)

        case .requestingEvent:
            requestEvent()

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .stopping(let completion):
            doStop(completion: completion)

        case .notInitialized,
             .stopped,
             .waitingForEventToProcess:
            break
        }

    }

    // MARK: - Lifecycle

    /// Responder method for `starting`. Starts the operation queue and subscribes to
    /// the publisher. After subscribing to the publisher, return actions:
    /// - receivedSubscription
    private func doStart(
        api: APICategoryGraphQLBehavior,
        mutationEventPublisher: MutationEventPublisher,
        reconciliationQueue: IncomingEventReconciliationQueue?
    ) {
        log.verbose(#function)
        self.api = api
        self.reconciliationQueue = reconciliationQueue

        queryMutationEventsFromStorage { [weak self] in
            guard let self else { return }
            guard case .starting = stateMachine.state else {
                log.debug("Unexpected state transition while performing `doStart()` during `.starting` state. Current state: \(stateMachine.state).")
                return
            }

            operationQueue.isSuspended = false
            // State machine notification to ".receivedSubscription" will be handled in `receive(subscription:)`
            mutationEventPublisher.publisher.subscribe(self)
        }
    }

    /// Responder method for `stopping`. Cancels all operations on the operation queue, suspends it,
    /// and cancels the publisher subscription. Return actions:
    /// - doneStopping
    private func doStop(completion: @escaping BasicClosure) {
        log.verbose(#function)
        doStopWithoutNotifyingStateMachine()
        stateMachine.notify(action: .doneStopping)
        completion()
    }

    private func doStopWithoutNotifyingStateMachine() {
        _ = sessionGeneration.increment()
        log.verbose(#function)
        subscription?.cancel()
        subscription = nil
        operationQueue.cancelAllOperations()
        operationQueue.isSuspended = true
        operationQueue.waitUntilAllOperationsAreFinished()
    }

    // MARK: - Event loop processing

    /// Responder method for `requestingEvent`. Requests an event from the subscription, and lets the subscription
    /// handler enqueue it. Return actions:
    /// - errored
    private func requestEvent() {
        log.verbose(#function)
        guard let subscription else {
            let dataStoreError = DataStoreError.unknown(
                "No subscription when requesting event",
                """
                The outgoing mutation queue attempted to request event without an active subscription.
                \(AmplifyErrorMessages.reportBugToAWS())
                """
            )
            stateMachine.notify(action: .errored(dataStoreError))
            return
        }
        requestedGeneration.set(sessionGeneration.get())
        subscription.request(.max(1))
    }

    /// Invoked when the subscription receives an event, not as part of the state machine transition
    private func enqueue(_ mutationEvent: MutationEvent) {
        log.verbose(#function)
        // The requesting session, so an event delivered across a stop is stale even if it arrives after the bump
        let generation = requestedGeneration.get()
        guard let api else {
            let dataStoreError = DataStoreError.configuration(
                "API is unexpectedly nil",
                """
                The reference to api has been released while an ongoing mutation was being processed.
                \(AmplifyErrorMessages.reportBugToAWS())
                """
            )
            stateMachine.notify(action: .errored(dataStoreError))
            return
        }

        Task {
            let syncMutationToCloudOperation = await SyncMutationToCloudOperation(
                mutationEvent: mutationEvent,
                getLatestSyncMetadata: { try? self.storageAdapter.queryMutationSyncMetadata(for: mutationEvent.modelId, modelName: mutationEvent.modelName) },
                api: api,
                authModeStrategy: authModeStrategy
            ) { [weak self] result in
                self?.log.verbose(
                    "[SyncMutationToCloudOperation] mutationEvent finished: \(mutationEvent.id); result: \(result)")
                self?.processSyncMutationToCloudResult(result, mutationEvent: mutationEvent, generation: generation, api: api)
            }

            // The event stays in the outbox, so the next session sends it.
            guard isCurrent(generation) else {
                log.verbose("Queue stopped while enqueueing mutationEvent \(mutationEvent.id), dropping it")
                return
            }
            dispatchOutboxMutationEnqueuedEvent(mutationEvent: mutationEvent)
            dispatchOutboxStatusEvent(isEmpty: false)
            operationQueue.addOperation(syncMutationToCloudOperation)
            stateMachine.notify(action: .enqueuedEvent)
        }
    }

    private func processSyncMutationToCloudResult(
        _ result: GraphQLOperation<MutationSync<AnyModel>>.OperationResult,
        mutationEvent: MutationEvent,
        generation: Int,
        api: APICategoryGraphQLBehavior
    ) {
        guard isCurrent(generation) else {
            log.verbose("Queue stopped while mutationEvent \(mutationEvent.id) was in flight, dropping its result")
            return
        }

        if case let .success(graphQLResponse) = result {
            if case let .success(graphQLResult) = graphQLResponse {
                processSuccessEvent(
                    mutationEvent,
                    generation: generation,
                    mutationSync: graphQLResult
                )
            } else if case let .failure(graphQLResponseError) = graphQLResponse {
                processMutationErrorFromCloud(
                    mutationEvent: mutationEvent,
                    generation: generation,
                    api: api,
                    apiError: nil,
                    graphQLResponseError: graphQLResponseError
                )
            }
        } else if case let .failure(apiError) = result {
            processMutationErrorFromCloud(
                mutationEvent: mutationEvent,
                generation: generation,
                api: api,
                apiError: apiError,
                graphQLResponseError: nil
            )
        }
    }

    /// Process the successful response from API by updating the mutation events in
    /// mutation event table having `nil` version
    private func processSuccessEvent(
        _ mutationEvent: MutationEvent,
        generation: Int,
        mutationSync: MutationSync<AnyModel>?
    ) {
        if let mutationSync {
            guard let reconciliationQueue else {
                let dataStoreError = DataStoreError.configuration(
                    "reconciliationQueue is unexpectedly nil",
                    """
                    The reference to reconciliationQueue has been released while an ongoing mutation was being processed.
                    \(AmplifyErrorMessages.reportBugToAWS())
                    """
                )
                stateMachine.notify(action: .errored(dataStoreError))
                return
            }
            reconciliationQueue.offer([mutationSync], modelName: mutationEvent.modelName)
            MutationEvent.reconcilePendingMutationEventsVersion(
                sent: mutationEvent,
                received: mutationSync,
                storageAdapter: storageAdapter
            ) { _ in
                self.completeProcessingEvent(mutationEvent, generation: generation, mutationSync: mutationSync)
            }
        } else {
            completeProcessingEvent(mutationEvent, generation: generation)
        }
    }

    private func processMutationErrorFromCloud(
        mutationEvent: MutationEvent,
        generation: Int,
        api: APICategoryGraphQLBehavior,
        apiError: APIError?,
        graphQLResponseError: GraphQLResponseError<MutationSync<AnyModel>>?
    ) {
        if let apiError, apiError.isOperationCancelledError {
            log.verbose("SyncMutationToCloudOperation was cancelled, aborting processing")
            return
        }

        let processMutationErrorFromCloudOperation = ProcessMutationErrorFromCloudOperation(
            dataStoreConfiguration: dataStoreConfiguration,
            mutationEvent: mutationEvent,
            api: api,
            storageAdapter: storageAdapter,
            graphQLResponseError: graphQLResponseError,
            apiError: apiError,
            reconciliationQueue: reconciliationQueue
        ) { [weak self] result in
            guard let self else {
                return
            }
            log.verbose("[ProcessMutationErrorFromCloudOperation] result: \(result)")
            if case let .success(mutationEventOptional) = result,
               let outgoingMutationEvent = mutationEventOptional {
                outgoingMutationQueueSubject.send(outgoingMutationEvent)
            }
            completeProcessingEvent(mutationEvent, generation: generation)
        }
        guard isCurrent(generation) else {
            return
        }
        operationQueue.addOperation(processMutationErrorFromCloudOperation)
    }

    private func completeProcessingEvent(
        _ mutationEvent: MutationEvent,
        generation: Int,
        mutationSync: MutationSync<AnyModel>? = nil
    ) {
        // A result that crosses a stop is re-sent after restart; a re-sent create then fails its condition check.
        guard isCurrent(generation) else {
            log.verbose("Queue stopped while processing mutationEvent \(mutationEvent.id), leaving it in the outbox")
            return
        }

        deleteProcessedEvent(mutationEvent)
        if let mutationSync {
            dispatchOutboxMutationProcessedEvent(
                mutationEvent: mutationEvent,
                mutationSync: mutationSync
            )
        }
        queryMutationEventsFromStorage { [weak self] in
            guard let self, isCurrent(generation) else { return }
            stateMachine.notify(action: .processedEvent)
        }
    }

    private func dispatchOutboxMutationProcessedEvent(
        mutationEvent: MutationEvent,
        mutationSync: MutationSync<AnyModel>
    ) {
        do {
            let localModel = try mutationEvent.decodeModel()
            let outboxMutationProcessedEvent = OutboxMutationEvent
                .fromModelWithMetadata(
                    modelName: mutationEvent.modelName,
                    model: localModel,
                    mutationSync: mutationSync
                )
            let payload = HubPayload(
                eventName: HubPayload.EventName.DataStore.outboxMutationProcessed,
                data: outboxMutationProcessedEvent
            )
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        } catch {
            log.error("\(#function) Couldn't decode local model as \(mutationEvent.modelName) \(error)")
            log.error("\(#function) Couldn't decode from \(mutationEvent.json)")
            return
        }
    }

    private func dispatchOutboxMutationEnqueuedEvent(mutationEvent: MutationEvent) {
        do {
            let localModel = try mutationEvent.decodeModel()
            let outboxMutationEnqueuedEvent = OutboxMutationEvent
                .fromModelWithoutMetadata(
                    modelName: mutationEvent.modelName,
                    model: localModel
                )
            let payload = HubPayload(
                eventName: HubPayload.EventName.DataStore.outboxMutationEnqueued,
                data: outboxMutationEnqueuedEvent
            )
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        } catch {
            log.error("\(#function) Couldn't decode local model as \(mutationEvent.modelName) \(error)")
            log.error("\(#function) Couldn't decode from \(mutationEvent.json)")
            return
        }
    }

    private func dispatchOutboxStatusEvent(isEmpty: Bool) {
        let outboxStatusEvent = OutboxStatusEvent(isEmpty: isEmpty)
        let outboxStatusEventPayload = HubPayload(
            eventName: HubPayload.EventName.DataStore.outboxStatus,
            data: outboxStatusEvent
        )
        Amplify.Hub.dispatch(to: .dataStore, payload: outboxStatusEventPayload)
    }

}

private extension OutgoingMutationQueue {
    func isCurrent(_ generation: Int) -> Bool {
        sessionGeneration.get() == generation
    }

    func queryMutationEventsFromStorage(onComplete: @escaping BasicClosure) {
        let fields = MutationEvent.keys
        let predicate = fields.inProcess == false || fields.inProcess == nil

        storageAdapter.query(
            MutationEvent.self,
            predicate: predicate,
            sort: nil,
            paginationInput: nil,
            eagerLoad: true
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let events):
                dispatchOutboxStatusEvent(isEmpty: events.isEmpty)
            case .failure(let error):
                log.error("Error querying mutation events: \(error)")
            }
            onComplete()
        }
    }

    /// Uses this queue's adapter, since the DataStore API would restart a stopped sync engine or recreate a cleared database.
    func deleteProcessedEvent(_ mutationEvent: MutationEvent) {
        storageAdapter.delete(
            untypedModelType: MutationEvent.self,
            modelSchema: MutationEvent.schema,
            withIdentifier: mutationEvent.identifier(schema: MutationEvent.schema),
            condition: nil
        ) { result in
            switch result {
            case .success:
                log.verbose("mutationEvent deleted successfully")
            case .failure(let error):
                log.verbose("mutationEvent failed to delete: error: \(error)")
            }
        }
    }
}

extension OutgoingMutationQueue: Subscriber {
    typealias Input = MutationEvent
    typealias Failure = DataStoreError

    func receive(subscription: Subscription) {
        log.verbose(#function)
        // Technically, saving the subscription should probably be done in a separate method, but it seems overkill
        // for a lightweight operation, not to mention that the transition from "receiving subscription" to "receiving
        // event" happens so quickly that state management becomes difficult.
        self.subscription = subscription
        stateMachine.notify(action: .receivedSubscription)
    }

    func receive(_ mutationEvent: MutationEvent) -> Subscribers.Demand {
        log.verbose(#function)
        enqueue(mutationEvent)
        return .none
    }

    // TODO: Resolve with an appropriate state machine notification
    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.verbose(#function)
        subscription?.cancel()
    }
}

extension OutgoingMutationQueue: Resettable {
    func reset() async {
        doStopWithoutNotifyingStateMachine()
    }
}

extension OutgoingMutationQueue: DefaultLogger {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.dataStore.displayName, forNamespace: String(describing: self))
    }
    var log: Logger {
        Self.log
    }
}
