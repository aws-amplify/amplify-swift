//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
class CloudSyncEngine: CloudSyncEngineBehavior {

    private weak var storageAdapter: StorageEngineAdapter?
    private weak var api: APICategoryGraphQLBehavior?

    // Assigned at `start`
    private var mutationQueue: OutgoingMutationQueue!

    /// Synchronizes startup operations
    let syncQueue: OperationQueue

    // Assigned at `setUpCloudSubscriptions`
    var reconciliationQueues: IncomingEventReconciliationQueues?

    init() {
        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStoreCategoryPlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API,
               storageAdapter: StorageEngineAdapter) {

        self.storageAdapter = storageAdapter
        self.api = api

        mutationQueue = OutgoingMutationQueue(storageAdapter: storageAdapter)

        // TODO: Refactor this into a reactive, state-based process
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
            self.startMutationQueue()
        }
        startMutationQueueOp.addDependency(activateCloudSubscriptionsOp)

        syncQueue.addOperations([
            pauseSubscriptionsOp,
            pauseMutationsOp,
            setUpCloudSubscriptionsOp,
            performInitialQueriesOp,
            activateCloudSubscriptionsOp,
            startMutationQueueOp
        ], waitUntilFinished: false)
    }

    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        log.verbose("submit: \(mutationEvent)")
        return mutationQueue.submit(mutationEvent: mutationEvent)
    }

    func asyncMutationEventSubject(for modelName: String) -> IncomingAsyncMutationEventSubject.Subject? {
        guard let reconciliationQueues = reconciliationQueues else {
            return nil
        }

        return reconciliationQueues.incomingMutationEventsSubject(for: modelName)
    }

    // MARK: - Startup sequence

    private func pauseSubscriptions() {
        log.debug(#function)
    }

    private func pauseMutations() {
        log.debug(#function)
        mutationQueue.pauseSyncingToCloud()
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

    private func startMutationQueue() {
        log.debug(#function)
        guard let api = api else {
            log.error(error: OutgoingMutationQueue.Errors.nilStorageAdapter)
            return
        }
        mutationQueue.startSyncingToCloud(syncEngine: self, api: api)
    }

}

extension CloudSyncEngine: DefaultLogger { }
