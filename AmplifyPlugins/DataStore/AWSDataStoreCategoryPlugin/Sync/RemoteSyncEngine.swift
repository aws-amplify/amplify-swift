//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

@available(iOS 13.0, *)
class RemoteSyncEngine: RemoteSyncEngineBehavior {

    private weak var storageAdapter: StorageEngineAdapter?

    // Assigned at `start`
    weak var api: APICategoryGraphQLBehavior?

    // Assigned and released inside `performInitialQueries`, but we maintain a reference so we can `reset`
    private var initialSyncOrchestrator: InitialSyncOrchestrator?
    private let initialSyncOrchestratorFactory: InitialSyncOrchestratorFactory

    private let mutationEventIngester: MutationEventIngester
    let mutationEventPublisher: MutationEventPublisher
    private let outgoingMutationQueue: OutgoingMutationQueueBehavior

    private var reconciliationQueueSink: AnyCancellable?

    let remoteSyncTopicPublisher: PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>
    var publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError> {
        return remoteSyncTopicPublisher.eraseToAnyPublisher()
    }

    /// Synchronizes startup operations
    private let syncQueue: OperationQueue
    private let workQueue = DispatchQueue(label: "com.amazonaws.RemoteSyncEngineOperationQueue",
                                          target: DispatchQueue.global())

    // Assigned at `setUpCloudSubscriptions`
    var reconciliationQueue: IncomingEventReconciliationQueue?
    var reconciliationQueueFactory: IncomingEventReconciliationQueueFactory

    let stateMachine: StateMachine<State, Action>
    private var stateMachineSink: AnyCancellable?

    var networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?
    var mutationRetryNotifier: MutationRetryNotifier?
    let requestRetryablePolicy: RequestRetryablePolicy
    var currentAttemptNumber: Int

    /// Initializes the CloudSyncEngine with the specified storageAdapter as the provider for persistence of
    /// MutationEvents, sync metadata, and conflict resolution metadata. Immediately initializes the incoming mutation
    /// queue so it can begin accepting incoming mutations from DataStore.
    convenience init(storageAdapter: StorageEngineAdapter,
                     outgoingMutationQueue: OutgoingMutationQueueBehavior? = nil,
                     initialSyncOrchestratorFactory: InitialSyncOrchestratorFactory? = nil,
                     reconciliationQueueFactory: IncomingEventReconciliationQueueFactory? = nil,
                     stateMachine: StateMachine<State, Action>? = nil,
                     networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>? = nil,
                     requestRetryablePolicy: RequestRetryablePolicy? = nil) throws {
        let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
        let outgoingMutationQueue = outgoingMutationQueue ?? OutgoingMutationQueue()
        let reconciliationQueueFactory = reconciliationQueueFactory ??
            AWSIncomingEventReconciliationQueue.init(modelTypes:api:storageAdapter:)
        let initialSyncOrchestratorFactory = initialSyncOrchestratorFactory ??
            AWSInitialSyncOrchestrator.init(api:reconciliationQueue:storageAdapter:)
        let stateMachine = stateMachine ?? StateMachine(initialState: .notStarted,
                                                        resolver: RemoteSyncEngine.Resolver.resolve(currentState:action:))
        let requestRetryablePolicy = requestRetryablePolicy ?? RequestRetryablePolicy()


        self.init(storageAdapter: storageAdapter,
                  outgoingMutationQueue: outgoingMutationQueue,
                  mutationEventIngester: mutationDatabaseAdapter,
                  mutationEventPublisher: awsMutationEventPublisher,
                  initialSyncOrchestratorFactory: initialSyncOrchestratorFactory,
                  reconciliationQueueFactory: reconciliationQueueFactory,
                  stateMachine: stateMachine,
                  networkReachabilityPublisher: networkReachabilityPublisher,
                  requestRetryablePolicy: requestRetryablePolicy)
    }

    init(storageAdapter: StorageEngineAdapter,
         outgoingMutationQueue: OutgoingMutationQueueBehavior,
         mutationEventIngester: MutationEventIngester,
         mutationEventPublisher: MutationEventPublisher,
         initialSyncOrchestratorFactory: @escaping InitialSyncOrchestratorFactory,
         reconciliationQueueFactory: @escaping IncomingEventReconciliationQueueFactory,
         stateMachine: StateMachine<State, Action>,
         networkReachabilityPublisher: AnyPublisher<ReachabilityUpdate, Never>?,
         requestRetryablePolicy: RequestRetryablePolicy) {
        self.storageAdapter = storageAdapter
        self.mutationEventIngester = mutationEventIngester
        self.mutationEventPublisher = mutationEventPublisher
        self.outgoingMutationQueue = outgoingMutationQueue
        self.initialSyncOrchestratorFactory = initialSyncOrchestratorFactory
        self.reconciliationQueueFactory = reconciliationQueueFactory
        self.remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()
        self.networkReachabilityPublisher = networkReachabilityPublisher
        self.requestRetryablePolicy = requestRetryablePolicy

        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStorePlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1

        self.currentAttemptNumber = 1

        self.stateMachine = stateMachine
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

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {
        case .notStarted:
            break
        case .pauseSubscriptions:
            pauseSubscriptions()
        case .pauseMutationQueue:
            pauseMutations()
        case .initializeSubscriptions(let api, let storageAdapter):
            initializeSubscriptions(api: api, storageAdapter: storageAdapter)
        case .performInitialSync:
            performInitialSync()
        case .activateCloudSubscriptions:
            activateCloudSubscriptions()
        case .activateMutationQueue(let api, let mutationEventPublisher):
            startMutationQueue(api: api, mutationEventPublisher: mutationEventPublisher)
        case .notifySyncStarted:
            notifySyncStarted()

        case .syncEngineActive:
            break

        case .cleanup(let error):
            cleanup(error: error)

        case .scheduleRestart(let error):
            scheduleRestart(error: error)
        }
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API) {
        self.api = api
        guard storageAdapter != nil else {
            log.error(error: DataStoreError.nilStorageAdapter())
            remoteSyncTopicPublisher.send(completion: .failure(DataStoreError.nilStorageAdapter()))
            return
        }

        remoteSyncTopicPublisher.send(.storageAdapterAvailable)
        stateMachine.notify(action: .receivedStart)
    }

    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        return mutationEventIngester.submit(mutationEvent: mutationEvent)
    }

    // MARK: - Startup sequence
    private func pauseSubscriptions() {
        log.debug(#function)
        reconciliationQueue?.pause()

        remoteSyncTopicPublisher.send(.subscriptionsPaused)
        stateMachine.notify(action: .pausedSubscriptions)
    }

    private func pauseMutations() {
        log.debug(#function)
        outgoingMutationQueue.pauseSyncingToCloud()

        remoteSyncTopicPublisher.send(.mutationsPaused)
        if let api = self.api, let storageAdapter = self.storageAdapter {
            stateMachine.notify(action: .pausedMutationQueue(api, storageAdapter))
        }
    }

    private func initializeSubscriptions(api: APICategoryGraphQLBehavior,
                                         storageAdapter: StorageEngineAdapter) {
        log.debug(#function)
        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }
        reconciliationQueue = reconciliationQueueFactory(syncableModelTypes, api, storageAdapter)
        reconciliationQueueSink = reconciliationQueue?.publisher.sink(
            receiveCompletion: onReceiveCompletion(receiveCompletion:),
            receiveValue: onReceive(receiveValue:))

        //Notifying the publisher & state machine are handled in:
        // RemoteSyncEngine+IncomingEventReconciliationQueueEvent.swift
    }

    private func performInitialSync() {
        log.debug(#function)

        let initialSyncOrchestrator = initialSyncOrchestratorFactory(api, reconciliationQueue, storageAdapter)

        // Hold a reference so we can `reset` while initial sync is in process
        self.initialSyncOrchestrator = initialSyncOrchestrator

        // TODO: This should be an AsynchronousOperation, not a semaphore-waited block
        let semaphore = DispatchSemaphore(value: 0)

        initialSyncOrchestrator.sync { result in
            if case .failure(let dataStoreError) = result {
                self.log.error(dataStoreError.errorDescription)
                self.log.error(dataStoreError.recoverySuggestion)
                if let underlyingError = dataStoreError.underlyingError {
                    self.log.error("\(underlyingError)")
                }

                self.stateMachine.notify(action: .errored(dataStoreError))
            } else {
                self.log.info("Successfully finished sync")

                self.remoteSyncTopicPublisher.send(.performedInitialSync)
                self.stateMachine.notify(action: .performedInitialSync)
            }
            semaphore.signal()
        }

        semaphore.wait()
        self.initialSyncOrchestrator = nil
    }

    private func activateCloudSubscriptions() {
        log.debug(#function)
        reconciliationQueue?.start()

        //Notifying the publisher & state machine are handled in:
        // RemoteSyncEngine+IncomingEventReconciliationQueueEvent.swift
    }

    private func startMutationQueue(api: APICategoryGraphQLBehavior,
                                    mutationEventPublisher: MutationEventPublisher) {
        log.debug(#function)
        outgoingMutationQueue.startSyncingToCloud(api: api, mutationEventPublisher: mutationEventPublisher)

        remoteSyncTopicPublisher.send(.mutationQueueStarted)
        stateMachine.notify(action: .activatedMutationQueue)
    }

    private func cleanup(error: AmplifyError?) {
        reconciliationQueue?.cancel()
        reconciliationQueue = nil
        outgoingMutationQueue.pauseSyncingToCloud()

        remoteSyncTopicPublisher.send(.cleanedUp)
        stateMachine.notify(action: .cleanedUp(error))
    }

    private func notifySyncStarted() {
        resetCurrentAttemptNumber()
        Amplify.Hub.dispatch(to: .dataStore,
                             payload: HubPayload(eventName: HubPayload.EventName.DataStore.syncStarted))

        remoteSyncTopicPublisher.send(.syncStarted)
        stateMachine.notify(action: .notifiedSyncStarted)
    }

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()

        group.enter()

        DispatchQueue.global().async {
            self.syncQueue.cancelAllOperations()
            self.syncQueue.waitUntilAllOperationsAreFinished()
        }

        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let resettable = child.value as? Resettable {
                DispatchQueue.global().async {
                    resettable.reset {
                        group.leave()
                    }
                }
            }
        }

        group.wait()
        onComplete()
    }
}

@available(iOS 13.0, *)
extension RemoteSyncEngine: DefaultLogger { }
