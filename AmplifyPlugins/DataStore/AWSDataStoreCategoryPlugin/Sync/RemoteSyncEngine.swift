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
    private weak var api: APICategoryGraphQLBehavior?

    // Assigned and released inside `performInitialQueries`, but we maintain a reference so we can `reset`
    private var initialSyncOrchestrator: InitialSyncOrchestrator?
    private let initialSyncOrchestratorFactory: InitialSyncOrchestratorFactory

    private let mutationEventIngester: MutationEventIngester
    private let mutationEventPublisher: MutationEventPublisher
    private let outgoingMutationQueue: OutgoingMutationQueueBehavior

    private var reconciliationQueueSink: AnyCancellable?

    private let remoteSyncTopicPublisher: PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>
    var publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError> {
        return remoteSyncTopicPublisher.eraseToAnyPublisher()
    }

    /// Synchronizes startup operations
    let syncQueue: OperationQueue

    // Assigned at `setUpCloudSubscriptions`
    var reconciliationQueue: IncomingEventReconciliationQueue?
    var reconciliationQueueFactory: IncomingEventReconciliationQueueFactory

    /// Initializes the CloudSyncEngine with the specified storageAdapter as the provider for persistence of
    /// MutationEvents, sync metadata, and conflict resolution metadata. Immediately initializes the incoming mutation
    /// queue so it can begin accepting incoming mutations from DataStore.
    convenience init(storageAdapter: StorageEngineAdapter,
                     outgoingMutationQueue: OutgoingMutationQueueBehavior? = nil,
                     initialSyncOrchestratorFactory: InitialSyncOrchestratorFactory? = nil,
                     reconciliationQueueFactory: IncomingEventReconciliationQueueFactory? = nil) throws {
        let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
        let outgoingMutationQueue = outgoingMutationQueue ?? OutgoingMutationQueue()
        let reconciliationQueueFactory = reconciliationQueueFactory ??
            AWSIncomingEventReconciliationQueue.init(modelTypes:api:storageAdapter:)
        let initialSyncOrchestratorFactory = initialSyncOrchestratorFactory ??
            AWSInitialSyncOrchestrator.init(api:reconciliationQueue:storageAdapter:)

        self.init(storageAdapter: storageAdapter,
                  outgoingMutationQueue: outgoingMutationQueue,
                  mutationEventIngester: mutationDatabaseAdapter,
                  mutationEventPublisher: awsMutationEventPublisher,
                  initialSyncOrchestratorFactory: initialSyncOrchestratorFactory,
                  reconciliationQueueFactory: reconciliationQueueFactory)
    }

    init(storageAdapter: StorageEngineAdapter,
         outgoingMutationQueue: OutgoingMutationQueueBehavior,
         mutationEventIngester: MutationEventIngester,
         mutationEventPublisher: MutationEventPublisher,
         initialSyncOrchestratorFactory: @escaping InitialSyncOrchestratorFactory,
         reconciliationQueueFactory: @escaping IncomingEventReconciliationQueueFactory) {
        self.storageAdapter = storageAdapter
        self.mutationEventIngester = mutationEventIngester
        self.mutationEventPublisher = mutationEventPublisher
        self.outgoingMutationQueue = outgoingMutationQueue
        self.initialSyncOrchestratorFactory = initialSyncOrchestratorFactory
        self.reconciliationQueueFactory = reconciliationQueueFactory
        self.remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()

        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStorePlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API) {

        self.api = api

        guard let storageAdapter = storageAdapter else {
            log.error(error: DataStoreError.nilStorageAdapter())
            remoteSyncTopicPublisher.send(completion: .failure(DataStoreError.nilStorageAdapter()))
            return
        }
        remoteSyncTopicPublisher.send(.storageAdapterAvailable)

        let pauseSubscriptionsOp = CancelAwareBlockOperation {
            self.pauseSubscriptions()
        }

        let pauseMutationsOp = CancelAwareBlockOperation {
            self.pauseMutations()
        }
        pauseMutationsOp.addDependency(pauseSubscriptionsOp)

        let setUpCloudSubscriptionsOp = CancelAwareBlockOperation {
            self.setUpCloudSubscriptions(api: api, storageAdapter: storageAdapter)
        }
        setUpCloudSubscriptionsOp.addDependency(pauseMutationsOp)

        let performInitialQueriesOp = CancelAwareBlockOperation {
            self.performInitialQueries()
        }
        performInitialQueriesOp.addDependency(setUpCloudSubscriptionsOp)

        let activateCloudSubscriptionsOp = CancelAwareBlockOperation {
            self.activateCloudSubscriptions()
        }
        activateCloudSubscriptionsOp.addDependency(performInitialQueriesOp)

        let startMutationQueueOp = CancelAwareBlockOperation {
            self.startMutationQueue(api: api, mutationEventPublisher: self.mutationEventPublisher)
        }
        startMutationQueueOp.addDependency(activateCloudSubscriptionsOp)

        let updateStateOp = CancelAwareBlockOperation {
            Amplify.Hub.dispatch(to: .dataStore,
                                 payload: HubPayload(eventName: HubPayload.EventName.DataStore.syncStarted))
            self.remoteSyncTopicPublisher.send(.syncStarted)
        }
        updateStateOp.addDependency(startMutationQueueOp)

        syncQueue.addOperations([
            pauseSubscriptionsOp,
            pauseMutationsOp,
            setUpCloudSubscriptionsOp,
            performInitialQueriesOp,
            activateCloudSubscriptionsOp,
            startMutationQueueOp,
            updateStateOp
        ], waitUntilFinished: false)
    }

    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        return mutationEventIngester.submit(mutationEvent: mutationEvent)
    }

    // MARK: - Startup sequence

    private func pauseSubscriptions() {
        log.debug(#function)
        reconciliationQueue?.pause()
    }

    private func pauseMutations() {
        log.debug(#function)
        outgoingMutationQueue.pauseSyncingToCloud()
        remoteSyncTopicPublisher.send(.mutationsPaused)
    }

    private func setUpCloudSubscriptions(api: APICategoryGraphQLBehavior,
                                         storageAdapter: StorageEngineAdapter) {
        log.debug(#function)
        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }
        reconciliationQueue = reconciliationQueueFactory(syncableModelTypes, api, storageAdapter)
        reconciliationQueueSink = reconciliationQueue?.publisher.sink(
            receiveCompletion: onReceiveCompletion(receiveCompletion:),
            receiveValue: onReceive(receiveValue:))
        remoteSyncTopicPublisher.send(.subscriptionsInitialized)
    }

    @available(iOS 13.0, *)
    private func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        if case .failure(let error) = receiveCompletion {
            self.remoteSyncTopicPublisher.send(completion: .failure(error))
        }
        if case .finished = receiveCompletion {
            let unexpectedFinishError = DataStoreError.unknown("ReconcilationQueue sent .finished message",
                                                               AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                                                               nil)
            self.remoteSyncTopicPublisher.send(completion: .failure(unexpectedFinishError))
        }
    }

    @available(iOS 13.0, *)
    private func onReceive(receiveValue: IncomingEventReconciliationQueueEvent) {
        switch receiveValue {
        case .started:
            remoteSyncTopicPublisher.send(.subscriptionsActivated)
        case .paused:
            remoteSyncTopicPublisher.send(.subscriptionsPaused)
        case .mutationEvent(let mutationEvent):
            remoteSyncTopicPublisher.send(.mutationEvent(mutationEvent))
        }
    }

    private func performInitialQueries() {
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
                self.remoteSyncTopicPublisher.send(completion: .failure(dataStoreError))
            } else {
                self.log.info("Successfully finished sync")
                self.remoteSyncTopicPublisher.send(.performedInitialSync)
            }
            semaphore.signal()
        }

        semaphore.wait()
        self.initialSyncOrchestrator = nil
    }

    private func activateCloudSubscriptions() {
        log.debug(#function)
        reconciliationQueue?.start()
    }

    private func startMutationQueue(api: APICategoryGraphQLBehavior,
                                    mutationEventPublisher: MutationEventPublisher) {
        log.debug(#function)
        outgoingMutationQueue.startSyncingToCloud(api: api, mutationEventPublisher: mutationEventPublisher)
        remoteSyncTopicPublisher.send(.mutationQueueStarted)
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
