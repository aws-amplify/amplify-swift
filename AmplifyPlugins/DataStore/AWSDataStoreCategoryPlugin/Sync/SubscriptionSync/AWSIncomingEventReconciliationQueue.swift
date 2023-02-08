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
@available(iOS 13.0, *)
typealias IncomingEventReconciliationQueueFactory =
    ([ModelSchema],
    APICategoryGraphQLBehavior,
    StorageEngineAdapter,
    [DataStoreSyncExpression],
    AuthCategoryBehavior?,
    AuthModeStrategy,
    ModelReconciliationQueueFactory?
) -> IncomingEventReconciliationQueue

@available(iOS 13.0, *)
final class AWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    private var modelReconciliationQueueSinks: [String: AnyCancellable]

    // swiftlint:disable:next line_length
    private let eventReconciliationQueueTopic: CurrentValueSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return eventReconciliationQueueTopic.eraseToAnyPublisher()
    }

    private let connectionStatusSerialQueue: DispatchQueue
    private var reconcileAndSaveQueue: ReconcileAndSaveOperationQueue
    private var reconciliationQueues: [ModelName: ModelReconciliationQueue]
    private var reconciliationQueueConnectionStatus: [ModelName: Bool]
    private var modelReconciliationQueueFactory: ModelReconciliationQueueFactory

    private var isInitialized: Bool {
        // swiftlint:disable:next line_length
        log.verbose("[InitializeSubscription.5] \(reconciliationQueueConnectionStatus.count)/\(modelSchemasCount) initialized")
        return modelSchemasCount == reconciliationQueueConnectionStatus.count
    }
    private let modelSchemasCount: Int

    init(modelSchemas: [ModelSchema],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         syncExpressions: [DataStoreSyncExpression],
         auth: AuthCategoryBehavior? = nil,
         authModeStrategy: AuthModeStrategy,
         modelReconciliationQueueFactory: ModelReconciliationQueueFactory? = nil) {
        self.modelSchemasCount = modelSchemas.count
        self.modelReconciliationQueueSinks = [:]
        self.eventReconciliationQueueTopic = .init(.idle)
        self.reconciliationQueues = [:]
        self.reconciliationQueueConnectionStatus = [:]
        self.reconcileAndSaveQueue = ReconcileAndSaveQueue(modelSchemas)
        self.modelReconciliationQueueFactory = modelReconciliationQueueFactory ?? AWSModelReconciliationQueue.init
        // swiftlint:disable:next todo
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
            guard reconciliationQueues[modelName] == nil else {
                log.warn("Duplicate model name found: \(modelName), not subscribing")
                continue
            }
            // swiftlint:disable:next line_length
            log.verbose("[InitializeSubscription.5] Creating reconciliationQueues \(modelName) \(reconciliationQueues.count)")
            let queue = self.modelReconciliationQueueFactory(modelSchema,
                                                             storageAdapter,
                                                             api,
                                                             reconcileAndSaveQueue,
                                                             modelPredicate,
                                                             auth,
                                                             authModeStrategy,
                                                             nil)
            reconciliationQueues[modelName] = queue
            // swiftlint:disable:next line_length
            log.verbose("[InitializeSubscription.5] Sink reconciliationQueues \(modelName) \(reconciliationQueues.count)")
            let modelReconciliationQueueSink = queue.publisher.sink(receiveCompletion: onReceiveCompletion(completed:),
                                                                    receiveValue: onReceiveValue(receiveValue:))
            // swiftlint:disable:next line_length
            log.verbose("[InitializeSubscription.5] Sink done reconciliationQueues \(modelName) \(reconciliationQueues.count)")
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
            // swiftlint:disable:next todo
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
        case .mutationEventDropped(let modelName, let error):
            eventReconciliationQueueTopic.send(.mutationEventDropped(modelName: modelName, error: error))
        case .connected(modelName: let modelName):
            connectionStatusSerialQueue.async {
                self.log.verbose("[InitializeSubscription.4] .connected \(modelName)")
                self.reconciliationQueueConnectionStatus[modelName] = true
                if self.isInitialized {
                    self.log.verbose("[InitializeSubscription.6] connected isInitialized")
                    self.eventReconciliationQueueTopic.send(.initialized)
                }
            }
        case .disconnected(modelName: let modelName, reason: .operationDisabled),
             .disconnected(modelName: let modelName, reason: .unauthorized):
            connectionStatusSerialQueue.async {
                // swiftlint:disable:next line_length
                self.log.verbose("[InitializeSubscription.4] subscription disconnected [\(modelName)] reason: [\(receiveValue)]")
                // A disconnected subscription due to operation disabled or unauthorized will still contribute
                // to the overall state of the reconciliation queue system on sending the `.initialized` event
                // since subscriptions may be disabled and have to reconcile locally sourced mutation evemts.
                self.reconciliationQueueConnectionStatus[modelName] = true
                if self.isInitialized {
                    Amplify.log.verbose("[InitializeSubscription.6] disconnected isInitialized")
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
@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue: DefaultLogger { }

// MARK: - Static factory
@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue {
    // swiftlint:disable:next line_length
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
@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in reconciliationQueues.values {
            guard let queue = queue as? Resettable else {
                continue
            }
            log.verbose("Resetting reconciliationQueue")
            group.enter()
            queue.reset {
                self.log.verbose("Resetting reconciliationQueue: finished")
                group.leave()
            }
        }

        log.verbose("Resetting reconcileAndSaveQueue")
        reconcileAndSaveQueue.cancelAllOperations()
        reconcileAndSaveQueue.waitUntilOperationsAreFinished()
        log.verbose("Resetting reconcileAndSaveQueue: finished")

        log.verbose("Cancelling AWSIncomingEventReconciliationQueue")
        group.enter()
        cancel {
            self.log.verbose("Cancelling AWSIncomingEventReconciliationQueue: finished")
            group.leave()
        }

        group.wait()
        onComplete()
    }

}
