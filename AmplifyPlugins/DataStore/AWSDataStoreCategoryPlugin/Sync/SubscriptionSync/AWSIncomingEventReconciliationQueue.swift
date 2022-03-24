//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

// Used for testing:
typealias IncomingEventReconciliationQueueFactory =
    ([ModelSchema],
    APICategoryGraphQLBehavior,
    StorageEngineAdapter,
    [DataStoreSyncExpression],
    AuthCategoryBehavior?,
    AuthModeStrategy,
    ModelReconciliationQueueFactory?
) -> IncomingEventReconciliationQueue

final class AWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    private var modelReconciliationQueueSinks: [String: AnyCancellable]

    private let eventReconciliationQueueTopic: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return eventReconciliationQueueTopic.eraseToAnyPublisher()
    }

    private let connectionStatusSerialQueue: DispatchQueue
    private var reconcileAndSaveQueue: ReconcileAndSaveOperationQueue
    private var reconciliationQueues: [ModelName: ModelReconciliationQueue]
    private var reconciliationQueueConnectionStatus: [ModelName: Bool]
    private var modelReconciliationQueueFactory: ModelReconciliationQueueFactory

    private var isInitialized: Bool {
        reconciliationQueueConnectionStatus.count == reconciliationQueues.count
    }

    init(modelSchemas: [ModelSchema],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         syncExpressions: [DataStoreSyncExpression],
         auth: AuthCategoryBehavior? = nil,
         authModeStrategy: AuthModeStrategy,
         modelReconciliationQueueFactory: ModelReconciliationQueueFactory? = nil) {
        self.modelReconciliationQueueSinks = [:]
        self.eventReconciliationQueueTopic = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        self.reconciliationQueues = [:]
        self.reconciliationQueueConnectionStatus = [:]
        self.reconcileAndSaveQueue = ReconcileAndSaveQueue(modelSchemas)
        self.modelReconciliationQueueFactory = modelReconciliationQueueFactory ?? AWSModelReconciliationQueue.init
        // TODO: Add target for SyncEngine system to help prevent thread explosion and increase performance
        // https://github.com/aws-amplify/amplify-ios/issues/399
        self.connectionStatusSerialQueue
            = DispatchQueue(label: "com.amazonaws.DataStore.AWSIncomingEventReconciliationQueue")

        for modelSchema in modelSchemas {
            let modelName = modelSchema.name
            let syncExpression = syncExpressions.first(where: {
                $0.modelSchema.name == modelName
            })
            let modelPredicate = syncExpression?.modelPredicate() ?? nil
            let queue = self.modelReconciliationQueueFactory(modelSchema,
                                                             storageAdapter,
                                                             api,
                                                             reconcileAndSaveQueue,
                                                             modelPredicate,
                                                             auth,
                                                             authModeStrategy,
                                                             nil)
            guard reconciliationQueues[modelName] == nil else {
                Amplify.DataStore.log
                    .warn("Duplicate model name found: \(modelName), not subscribing")
                continue
            }
            reconciliationQueues[modelName] = queue
            let modelReconciliationQueueSink = queue.publisher.sink(receiveCompletion: onReceiveCompletion(completed:),
                                                                    receiveValue: onReceiveValue(receiveValue:))
            modelReconciliationQueueSinks[modelName] = modelReconciliationQueueSink
        }
    }

    func start() {
        reconciliationQueues.values.forEach { $0.start() }
        eventReconciliationQueueTopic.send(.started)
    }

    func pause() {
        reconciliationQueues.values.forEach { $0.pause() }
        eventReconciliationQueueTopic.send(.paused)
    }

    func offer(_ remoteModels: [MutationSync<AnyModel>], modelName: ModelName) {
        guard let queue = reconciliationQueues[modelName] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModels)
    }

    private func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        connectionStatusSerialQueue.async {
            self.reconciliationQueueConnectionStatus = [:]
        }
        switch completed {
        case .failure(let error):
            eventReconciliationQueueTopic.send(completion: .failure(error))
        case .finished:
            eventReconciliationQueueTopic.send(completion: .finished)
        }
    }

    private func onReceiveValue(receiveValue: ModelReconciliationQueueEvent) {
        switch receiveValue {
        case .mutationEvent(let event):
            eventReconciliationQueueTopic.send(.mutationEventApplied(event))
        case .mutationEventDropped(let modelName):
            eventReconciliationQueueTopic.send(.mutationEventDropped(modelName: modelName))
        case .connected(modelName: let modelName):
            connectionStatusSerialQueue.async {
                self.reconciliationQueueConnectionStatus[modelName] = true
                if self.isInitialized {
                    self.eventReconciliationQueueTopic.send(.initialized)
                }
            }
        case .disconnected(modelName: let modelName, reason: .operationDisabled),
             .disconnected(modelName: let modelName, reason: .unauthorized):
            connectionStatusSerialQueue.async {
                Amplify.log.debug("Disconnected subscription for \(modelName) reason: \(receiveValue)")
                // A disconnected subscription due to operation disabled or unauthorized will still contribute
                // to the overall state of the reconciliation queue system on sending the `.initialized` event
                // since subscriptions may be disabled and have to reconcile locally sourced mutation evemts.
                self.reconciliationQueueConnectionStatus[modelName] = true
                if self.isInitialized {
                    self.eventReconciliationQueueTopic.send(.initialized)
                }
            }
        default:
            break
        }
    }

    func cancel() {
        cancel(completion: nil)
    }

    private func cancel(completion: BasicClosure?) {
        modelReconciliationQueueSinks.values.forEach { $0.cancel() }
        reconciliationQueues.values.forEach { $0.cancel()}
        connectionStatusSerialQueue.async {
            self.reconciliationQueues = [:]
            self.modelReconciliationQueueSinks = [:]
            completion?()
        }
    }

    private func dispatchSyncQueriesReady() {
        let syncQueriesReadyPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyPayload)
    }

}

// MARK: - Static factory
extension AWSIncomingEventReconciliationQueue {
    static let factory: IncomingEventReconciliationQueueFactory = { modelSchemas, api, storageAdapter, syncExpressions, auth, authModeStrategy, _ in
        AWSIncomingEventReconciliationQueue(modelSchemas: modelSchemas,
                                            api: api,
                                            storageAdapter: storageAdapter,
                                            syncExpressions: syncExpressions,
                                            auth: auth,
                                            authModeStrategy: authModeStrategy,
                                            modelReconciliationQueueFactory: nil)
    }
}

// MARK: - AWSIncomingEventReconciliationQueue + Resettable
extension AWSIncomingEventReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in reconciliationQueues.values {
            guard let queue = queue as? Resettable else {
                continue
            }
            Amplify.log.verbose("Resetting reconciliationQueue")
            group.enter()
            queue.reset {
                Amplify.log.verbose("Resetting reconciliationQueue: finished")
                group.leave()
            }
        }

        Amplify.log.verbose("Resetting reconcileAndSaveQueue")
        reconcileAndSaveQueue.cancelAllOperations()
        reconcileAndSaveQueue.waitUntilOperationsAreFinished()
        Amplify.log.verbose("Resetting reconcileAndSaveQueue: finished")

        Amplify.log.verbose("Cancelling AWSIncomingEventReconciliationQueue")
        group.enter()
        cancel {
            Amplify.log.verbose("Cancelling AWSIncomingEventReconciliationQueue: finished")
            group.leave()
        }

        group.wait()
        onComplete()
    }

}
