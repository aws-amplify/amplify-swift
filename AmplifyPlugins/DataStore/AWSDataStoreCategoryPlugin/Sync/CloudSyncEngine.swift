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
class CloudSyncEngine: CloudSyncEngineBehavior {

    private weak var storageAdapter: StorageEngineAdapter?

    // Assigned at `start`
    private weak var api: APICategoryGraphQLBehavior?

    private let mutationEventIngester: MutationEventIngester
    private let mutationEventPublisher: MutationEventPublisher
    private let outgoingMutationQueue: OutgoingMutationQueue

    /// Synchronizes startup operations
    let syncQueue: OperationQueue

    // Assigned at `setUpCloudSubscriptions`
    var reconciliationQueues: IncomingEventReconciliationQueues?

    convenience init(storageAdapter: StorageEngineAdapter) {
        let awsMutationEventIngester = AWSMutationEventIngester(storageAdapter: storageAdapter)
        self.init(storageAdapter: storageAdapter,
                  mutationEventIngester: awsMutationEventIngester,
                  mutationEventPublisher: awsMutationEventIngester)
    }

    init(storageAdapter: StorageEngineAdapter,
         mutationEventIngester: MutationEventIngester,
         mutationEventPublisher: MutationEventPublisher) {
        self.storageAdapter = storageAdapter
        self.mutationEventIngester = mutationEventIngester
        self.mutationEventPublisher = mutationEventPublisher

        self.outgoingMutationQueue = OutgoingMutationQueue()

        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStoreCategoryPlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API) {

        // TODO: Refactor this into a reactive, state-based process

        self.api = api

        guard let storageAdapter = storageAdapter else {
            // TODO: Fail the operation if storage adapter is for some reason missing
            return
        }

        let pauseSubscriptionsOp = BlockOperation {
            self.pauseSubscriptions()
        }

        let pauseMutationsOp = BlockOperation {
            self.pauseMutations()
        }
        pauseMutationsOp.addDependency(pauseSubscriptionsOp)

        let setUpCloudSubscriptionsOp = BlockOperation {
            self.setUpCloudSubscriptions(api: api, storageAdapter: storageAdapter)
        }
        setUpCloudSubscriptionsOp.addDependency(pauseMutationsOp)

        let performInitialQueriesOp = BlockOperation {
            self.performInitialQueries()
        }
        performInitialQueriesOp.addDependency(setUpCloudSubscriptionsOp)

        let activateCloudSubscriptionsOp = BlockOperation {
            self.activateCloudSubscriptions()
        }
        activateCloudSubscriptionsOp.addDependency(performInitialQueriesOp)

        let startMutationQueueOp = BlockOperation {
            self.startMutationQueue(api: api, mutationEventPublisher: self.mutationEventPublisher)
        }
        startMutationQueueOp.addDependency(activateCloudSubscriptionsOp)

        let updateStateOp = BlockOperation {
            Amplify.Hub.dispatch(to: .dataStore,
                                 payload: HubPayload(eventName: HubPayload.EventName.DataStore.syncStarted))
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
    }

    private func pauseMutations() {
        log.debug(#function)
        outgoingMutationQueue.pauseSyncingToCloud()
        // TODO: Implement this
//        reconciliationQueues.pause()
    }

    private func setUpCloudSubscriptions(api: APICategoryGraphQLBehavior,
                                         storageAdapter: StorageEngineAdapter) {
        log.debug(#function)
        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }
        reconciliationQueues = IncomingEventReconciliationQueues(modelTypes: syncableModelTypes,
                                                                 api: api,
                                                                 storageAdapter: storageAdapter)
    }

    private func performInitialQueries() {
        log.debug(#function)
        // TODO: Implement this
    }

    private func activateCloudSubscriptions() {
        log.debug(#function)
        reconciliationQueues?.start()
    }

    private func startMutationQueue(api: APICategoryGraphQLBehavior,
                                    mutationEventPublisher: MutationEventPublisher) {
        log.debug(#function)
        outgoingMutationQueue.startSyncingToCloud(api: api, mutationEventPublisher: mutationEventPublisher)
    }

}

extension CloudSyncEngine: DefaultLogger { }
