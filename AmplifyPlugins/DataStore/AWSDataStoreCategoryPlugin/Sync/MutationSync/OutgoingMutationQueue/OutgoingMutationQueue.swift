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

/// Submits outgoing mutation events to the provisioned API
@available(iOS 13.0, *)
protocol OutgoingMutationQueueBehavior: class {
    func pauseSyncingToCloud()
    func startSyncingToCloud(api: APICategoryGraphQLBehavior,
                             mutationEventPublisher: MutationEventPublisher)
    var publisher: AnyPublisher<MutationEvent, Never> { get }
}

@available(iOS 13.0, *)
final class OutgoingMutationQueue: OutgoingMutationQueueBehavior {

    private let stateMachine: StateMachine<State, Action>
    private var stateMachineSink: AnyCancellable?

    private let operationQueue: OperationQueue

    private let workQueue = DispatchQueue(label: "com.amazonaws.OutgoingMutationOperationQueue",
                                          target: DispatchQueue.global())

    private weak var api: APICategoryGraphQLBehavior?
    private var subscription: Subscription?
    private let dataStoreConfiguration: DataStoreConfiguration
    private let storageAdapter: StorageEngineAdapter

    private let outgoingMutationQueueSubject: PassthroughSubject<MutationEvent, Never>
    public var publisher: AnyPublisher<MutationEvent, Never> {
        return outgoingMutationQueueSubject.eraseToAnyPublisher()
    }

    init(_ stateMachine: StateMachine<State, Action>? = nil,
         storageAdapter: StorageEngineAdapter,
         dataStoreConfiguration: DataStoreConfiguration) {
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        let operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.OutgoingMutationOperationQueue"
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true

        self.operationQueue = operationQueue

        self.stateMachine = stateMachine ??
            StateMachine(initialState: .notInitialized,
                         resolver: OutgoingMutationQueue.Resolver.resolve(currentState:action:))

        self.outgoingMutationQueueSubject = PassthroughSubject<MutationEvent, Never>()

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

        log.verbose("Initialized")
        self.stateMachine.notify(action: .initialized)
    }

    // MARK: - Public API

    func startSyncingToCloud(api: APICategoryGraphQLBehavior,
                             mutationEventPublisher: MutationEventPublisher) {
        log.verbose(#function)
        stateMachine.notify(action: .receivedStart(api, mutationEventPublisher))
    }

    func cancel() {
        log.verbose(#function)
        // Techncially this should be in a "cancelling" responder, but it's simpler to cancel here and move straight
        // to .finished. If in the future we need to add more work to the teardown state, move it to a separate method.
        operationQueue.cancelAllOperations()
        stateMachine.notify(action: .receivedCancel)
    }

    func pauseSyncingToCloud() {
        log.verbose(#function)
        operationQueue.isSuspended = true
    }

    // MARK: - Responders

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {

        case .starting(let api, let mutationEventPublisher):
            start(api: api, mutationEventPublisher: mutationEventPublisher)

        case .requestingEvent:
            requestEvent()

        case .resumingMutationQueue:
            resumeSyncingToCloud()

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .notInitialized,
             .notStarted,
             .finished,
             .waitingForEventToProcess,
             .resumed:
            break
        }

    }

    func resumeSyncingToCloud() {
        log.verbose(#function)
        operationQueue.isSuspended = false
        stateMachine.notify(action: .resumedSyncingToCloud)
    }

    /// Responder method for `starting`. Starts the operation queue and subscribes to the publisher. Return actions:
    /// - started
    private func start(api: APICategoryGraphQLBehavior,
                       mutationEventPublisher: MutationEventPublisher) {
        log.verbose(#function)
        self.api = api

        queryMutationEventsFromStorage(onComplete: {
            self.operationQueue.isSuspended = false
            // State machine notification to ".receivedSubscription" will be handled in `receive(subscription:)`
            mutationEventPublisher.publisher.subscribe(self)
        })
    }

    // MARK: - Event loop processing

    /// Responder method for `requestingEvent`. Requests an event from the subscription, and lets the subscription
    /// handler enqueue it. Return actions:
    /// - errored
    private func requestEvent() {
        log.verbose(#function)
        guard let subscription = subscription else {
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
        subscription.request(.max(1))
    }

    /// Invoked when the subscription receives an event, not as part of the state machine transition
    private func enqueue(_ mutationEvent: MutationEvent) {
        log.verbose(#function)
        guard let api = api else {
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

        let syncMutationToCloudOperation = SyncMutationToCloudOperation(
            mutationEvent: mutationEvent,
            api: api) { result in
                self.log.verbose(
                    "[SyncMutationToCloudOperation] mutationEvent finished: \(mutationEvent.id); result: \(result)")
                self.processSyncMutationToCloudResult(result, mutationEvent: mutationEvent, api: api)
        }

        dispatchOutboxMutationEnqueuedEvent(mutationEvent: mutationEvent)
        dispatchOutboxStatusEvent(isEmpty: false)
        operationQueue.addOperation(syncMutationToCloudOperation)
        stateMachine.notify(action: .enqueuedEvent)
    }

    private func processSyncMutationToCloudResult(_ result: GraphQLOperation<MutationSync<AnyModel>>.OperationResult,
                                                  mutationEvent: MutationEvent,
                                                  api: APICategoryGraphQLBehavior) {
        if case let .success(graphQLResponse) = result {
            if case let .success(graphQLResult) = graphQLResponse {
                completeProcessingEvent(mutationEvent,
                                        mutationSyncMetadata: graphQLResult)
            } else if case let .failure(graphQLResponseError) = graphQLResponse {
                processMutationErrorFromCloud(mutationEvent: mutationEvent,
                                              api: api,
                                              apiError: nil,
                                              graphQLResponseError: graphQLResponseError)
            }
        } else if case let .failure(apiError) = result {
            processMutationErrorFromCloud(mutationEvent: mutationEvent,
                                          api: api,
                                          apiError: apiError,
                                          graphQLResponseError: nil)
        }
    }

    private func processMutationErrorFromCloud(mutationEvent: MutationEvent,
                                               api: APICategoryGraphQLBehavior,
                                               apiError: APIError?,
                                               graphQLResponseError: GraphQLResponseError<MutationSync<AnyModel>>?) {
        let processMutationErrorFromCloudOperation = ProcessMutationErrorFromCloudOperation(
            dataStoreConfiguration: dataStoreConfiguration,
            mutationEvent: mutationEvent,
            api: api,
            storageAdapter: storageAdapter,
            graphQLResponseError: graphQLResponseError,
            apiError: apiError) { result in
                self.log.verbose("[ProcessMutationErrorFromCloudOperation] result: \(result)")
                if case let .success(mutationEventOptional) = result,
                    let outgoingMutationEvent = mutationEventOptional {
                    self.outgoingMutationQueueSubject.send(outgoingMutationEvent)
                }
                self.completeProcessingEvent(mutationEvent,
                                             mutationSyncMetadata: nil)
        }
        operationQueue.addOperation(processMutationErrorFromCloudOperation)
    }

    private func completeProcessingEvent(_ mutationEvent: MutationEvent,
                                         mutationSyncMetadata: MutationSync<AnyModel>?) {
        // This doesn't belong here--need to add a `delete` API to the MutationEventSource and pass a
        // reference into the mutation queue.
        Amplify.DataStore.delete(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                self.log.verbose("mutationEvent failed to delete: error: \(dataStoreError)")
            case .success:
                self.log.verbose("mutationEvent deleted successfully")
            }

            if let mutationSyncMetadata = mutationSyncMetadata {
                self.dispatchOutboxMutationProcessedEvent(mutationEvent: mutationEvent,
                                                          mutationSync: mutationSyncMetadata)
            }
            self.queryMutationEventsFromStorage {
                self.stateMachine.notify(action: .processedEvent)
            }
        }
    }

    private func queryMutationEventsFromStorage(onComplete: @escaping (() -> Void)) {
        let fields = MutationEvent.keys
        let predicate = fields.inProcess == false || fields.inProcess == nil

        storageAdapter.query(MutationEvent.self,
                             predicate: predicate,
                             sort: nil,
                             paginationInput: nil) { result in
            switch result {
            case .success(let events):
                self.dispatchOutboxStatusEvent(isEmpty: events.isEmpty)
            case .failure(let error):
                log.error("Error querying mutation events: \(error)")
            }
            onComplete()
        }
    }

    private func dispatchOutboxMutationProcessedEvent(mutationEvent: MutationEvent,
                                                      mutationSync: MutationSync<AnyModel>) {
        do {
            let localModel = try mutationEvent.decodeModel()
            let outboxMutationProcessedEvent = OutboxMutationEvent
                .fromModelWithMetadata(modelName: mutationEvent.modelName,
                                       model: localModel,
                                       mutationSync: mutationSync)
            let payload = HubPayload(eventName: HubPayload.EventName.DataStore.outboxMutationProcessed,
                                     data: outboxMutationProcessedEvent)
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        } catch {
            log.error("\(#function) Couldn't decode local model as \(mutationEvent.modelName)")
            return
        }
    }

    private func dispatchOutboxMutationEnqueuedEvent(mutationEvent: MutationEvent) {
        do {
            let localModel = try mutationEvent.decodeModel()
            let outboxMutationEnqueuedEvent = OutboxMutationEvent
                .fromModelWithoutMetadata(modelName: mutationEvent.modelName,
                                          model: localModel)
            let payload = HubPayload(eventName: HubPayload.EventName.DataStore.outboxMutationEnqueued,
                                     data: outboxMutationEnqueuedEvent)
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
        } catch {
            log.error("\(#function) Couldn't decode local model as \(mutationEvent.modelName)")
            return
        }
    }

    private func dispatchOutboxStatusEvent(isEmpty: Bool) {
        let outboxStatusEvent = OutboxStatusEvent(isEmpty: isEmpty)
        let outboxStatusEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.outboxStatus,
                                                  data: outboxStatusEvent)
        Amplify.Hub.dispatch(to: .dataStore, payload: outboxStatusEventPayload)
    }

}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension OutgoingMutationQueue: DefaultLogger { }
