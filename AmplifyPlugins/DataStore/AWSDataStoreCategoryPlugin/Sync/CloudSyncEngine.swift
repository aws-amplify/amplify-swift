//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

@available(iOS 13.0, *)
/// Behavior to sync mutation events to the cloud, and to subscribe to mutations from the cloud
protocol CloudSyncEngineBehavior {
    /// Used for testing
    typealias Factory = () -> CloudSyncEngineBehavior

    /// Start the sync process with a "delta sync" merge
    ///
    /// The order of the startup sequence is important:
    /// 1. Subscription and Mutation processing to the network are paused
    /// 1. Subscription connections are established and incoming messages are written to a queue
    /// 1. Queries are run and objects applied to the Datastore
    /// 1. Subscription processing runs off the queue and flows as normal, reconciling any items against
    ///    the updates in the Datastore
    /// 1. Mutation processor drains messages off the queue in serial and sends to the service, invoking
    ///    any local callbacks on error if necessary
    func start(api: APICategoryGraphQLBehavior, storageAdapter: StorageEngineAdapter)

    /// Submits a new mutation for synchronization to the cloud. The response will be handled by the appropriate
    /// reconciliation queue
    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError>
}

@available(iOS 13.0, *)
class CloudSyncEngine: CloudSyncEngineBehavior {

    // Assigned at `start`
    private var mutationQueue: OutgoingMutationQueue!

    // Assigned at `start`
    private var subscriber: SyncEngineMutationSubscriber!

    /// Synchronizes startup operations
    let syncQueue: OperationQueue

    var reconciliationQueues: IncomingEventReconciliationQueues?

    init() {
        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStoreCategoryPlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API,
               storageAdapter: StorageEngineAdapter) {

        mutationQueue = OutgoingMutationQueue(storageAdapter: storageAdapter)

        subscriber = SyncEngineMutationSubscriber(api: api)

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
        return mutationQueue.enqueue(event: mutationEvent)
    }

    // MARK: - Startup sequence
    private func pauseSubscriptions() {
        log.debug("pauseSubscriptions")
    }

    private func pauseMutations() {
        log.debug("pauseMutations")
    }

    private func setUpCloudSubscriptions(api: APICategoryGraphQLBehavior,
                                         storageAdapter: StorageEngineAdapter) {
        let syncableModelTypes = ModelRegistry.models.filter { $0.schema.isSyncable }
        reconciliationQueues = IncomingEventReconciliationQueues(modelTypes: syncableModelTypes,
                                                                 api: api,
                                                                 storageAdapter: storageAdapter)
    }

    private func performInitialQueries() {
        log.debug("performInitialQueries")
    }

    private func activateCloudSubscriptions() {
        log.debug("activateCloudSubscriptions")
    }

    private func startMutationQueue() {
        log.debug("startMutationQueue")
        mutationQueue.subscribe(subscriber: subscriber)
    }

}
