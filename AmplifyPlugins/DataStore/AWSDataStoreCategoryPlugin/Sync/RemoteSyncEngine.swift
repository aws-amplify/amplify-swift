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
class RemoteSyncEngine: RemoteSyncEngineBehavior {
    private weak var storageAdapter: StorageEngineAdapter?

    // Assigned at `start`
    private weak var api: APICategoryGraphQLBehavior?

    private let mutationEventIngester: MutationEventIngester
    private let mutationEventPublisher: MutationEventPublisher
    private let outgoingMutationQueue: OutgoingMutationQueueBehavior

    /// Synchronizes startup operations
    let syncQueue: OperationQueue

    // Assigned at `setUpCloudSubscriptions`
    var reconciliationQueues: IncomingEventReconciliationQueues?

    /// Initializes the CloudSyncEngine with the specified storageAdapter as the provider for persistence of
    /// MutationEvents, synce metadata, and conflict resolution metadata. Immediately initializes the incoming mutation
    /// queue so it can begin accepting incoming mutations from DataStore.
    convenience init(storageAdapter: StorageEngineAdapter) throws {
        let mutationDatabaseAdapter = try AWSMutationDatabaseAdapter(storageAdapter: storageAdapter)
        let awsMutationEventPublisher = AWSMutationEventPublisher(eventSource: mutationDatabaseAdapter)
        let outgoingMutationQueue = OutgoingMutationQueue()
        self.init(storageAdapter: storageAdapter,
                  outgoingMutationQueue: outgoingMutationQueue,
                  mutationEventIngester: mutationDatabaseAdapter,
                  mutationEventPublisher: awsMutationEventPublisher)
    }

    init(storageAdapter: StorageEngineAdapter,
         outgoingMutationQueue: OutgoingMutationQueueBehavior,
         mutationEventIngester: MutationEventIngester,
         mutationEventPublisher: MutationEventPublisher) {
        self.storageAdapter = storageAdapter
        self.mutationEventIngester = mutationEventIngester
        self.mutationEventPublisher = mutationEventPublisher
        self.outgoingMutationQueue = outgoingMutationQueue

        self.syncQueue = OperationQueue()
        syncQueue.name = "com.amazonaws.Amplify.\(AWSDataStorePlugin.self).CloudSyncEngine"
        syncQueue.maxConcurrentOperationCount = 1
    }

    func start(api: APICategoryGraphQLBehavior = Amplify.API) {

        // TODO: Refactor this into a reactive, state-based process

        self.api = api

        guard let storageAdapter = storageAdapter else {
            // TODO: Fail the operation if storage adapter is for some reason missing
            return
        }

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

    func reset(onComplete: () -> Void) {
        syncQueue.cancelAllOperations()
        syncQueue.waitUntilAllOperationsAreFinished()

        let group = DispatchGroup()
        if let awsMutationEventIngester = mutationEventIngester as? AWSMutationDatabaseAdapter {
            group.enter()
            DispatchQueue.global().async {
                awsMutationEventIngester.reset {
                    group.leave()
                }
            }
        }

        if let awsMutationEventPublisher = mutationEventPublisher as? AWSMutationEventPublisher {
            group.enter()
            DispatchQueue.global().async {
                awsMutationEventPublisher.reset {
                    group.leave()
                }
            }
        }

        if let reconciliationQueues = reconciliationQueues {
            group.enter()
            reconciliationQueues.reset {
                group.leave()
            }
        }

        group.wait()
        onComplete()
    }
}

final class CancelAwareBlockOperation: Operation {
    private let block: BasicClosure
    init(block: @escaping BasicClosure) {
        self.block = block
    }

    override func main() {
        guard !isCancelled else {
            return
        }
        block()
    }
}

@available(iOS 13, *)
extension RemoteSyncEngine: DefaultLogger { }
