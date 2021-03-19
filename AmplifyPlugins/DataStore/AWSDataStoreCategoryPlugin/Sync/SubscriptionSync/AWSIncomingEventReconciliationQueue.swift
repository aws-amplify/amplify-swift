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

//Used for testing:
@available(iOS 13.0, *)
typealias IncomingEventReconciliationQueueFactory =
    ([ModelSchema],
    APICategoryGraphQLBehavior,
    StorageEngineAdapter,
    [DataStoreSyncExpression],
    AuthCategoryBehavior?,
    ModelGroupReconciliationQueueFactory?
) -> IncomingEventReconciliationQueue

@available(iOS 13.0, *)
final class AWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    static let factory: IncomingEventReconciliationQueueFactory = { modelSchemas, api, storageAdapter, syncExpressions, auth, _ in
        AWSIncomingEventReconciliationQueue(modelSchemas: modelSchemas,
                                            api: api,
                                            storageAdapter: storageAdapter,
                                            syncExpressions: syncExpressions,
                                            auth: auth,
                                            modelGroupReconciliationQueueFactory: nil)
    }
    private var modelReconciliationQueueSinks: [String: AnyCancellable]

    private let eventReconciliationQueueTopic: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return eventReconciliationQueueTopic.eraseToAnyPublisher()
    }

    private let connectionStatusSerialQueue: DispatchQueue
    private var newReconciliationQueues: [ModelName: ModelReconciliationQueue]
    private var reconciliationQueueConnectionStatus: [ModelName: Bool]
    private var modelGroupReconciliationQueueFactory: ModelGroupReconciliationQueueFactory

    private var isInitialized: Bool {
        reconciliationQueueConnectionStatus.count == newReconciliationQueues.count
    }

    init(modelSchemas: [ModelSchema],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter,
         syncExpressions: [DataStoreSyncExpression],
         auth: AuthCategoryBehavior? = nil,
         modelGroupReconciliationQueueFactory: ModelGroupReconciliationQueueFactory? = nil) {
        self.modelReconciliationQueueSinks = [:]
        self.eventReconciliationQueueTopic = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        self.newReconciliationQueues = [:]
        self.reconciliationQueueConnectionStatus = [:]
        self.modelGroupReconciliationQueueFactory = modelGroupReconciliationQueueFactory ??
            AWSModelGroupReconciliationQueue.init(modelSchemas:storageAdapter:syncExpressions:api:auth:incomingSubscriptionEvents:)
        //TODO: Add target for SyncEngine system to help prevent thread explosion and increase performance
        // https://github.com/aws-amplify/amplify-ios/issues/399
        self.connectionStatusSerialQueue
            = DispatchQueue(label: "com.amazonaws.DataStore.AWSIncomingEventReconciliationQueue")
        for (modelName, connectedModelGroupSet) in modelSchemas.groupByConnectedModels() {
            if newReconciliationQueues[modelName] != nil {
                continue
            } else {
                let groupQueue = self.modelGroupReconciliationQueueFactory(modelSchemas,
                                                                           storageAdapter,
                                                                           syncExpressions,
                                                                           api,
                                                                           auth,
                                                                           nil)
                let groupQueueSink = groupQueue.publisher.sink(receiveCompletion: onReceiveCompletion(completed:),
                                                               receiveValue: onReceiveValue(receiveValue:))
                modelReconciliationQueueSinks[modelName] = groupQueueSink
//                // for each model in the model group
                for model in connectedModelGroupSet {
                    newReconciliationQueues[model] = groupQueue
                }
            }
        }
    }

    func start() {
        newReconciliationQueues.values.forEach { $0.start() }
        eventReconciliationQueueTopic.send(.started)
    }

    func pause() {
        newReconciliationQueues.values.forEach { $0.pause() }
        eventReconciliationQueueTopic.send(.paused)
    }

    func offer(_ remoteModel: MutationSync<AnyModel>, modelSchema: ModelSchema) {
        guard let queue = newReconciliationQueues[modelSchema.name] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModel)
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
        case .disconnected(modelName: let modelName, reason: .unauthorized):
            connectionStatusSerialQueue.async {
                self.newReconciliationQueues[modelName]?.cancel()
                self.modelReconciliationQueueSinks[modelName]?.cancel()
                self.reconciliationQueueConnectionStatus[modelName] = false
                if self.isInitialized {
                    self.eventReconciliationQueueTopic.send(.initialized)
                }
            }
        default:
            break
        }
    }

    func cancel() {
        modelReconciliationQueueSinks.values.forEach { $0.cancel() }
        newReconciliationQueues.values.forEach { $0.cancel()}
        connectionStatusSerialQueue.async {
            self.newReconciliationQueues = [:]
            self.modelReconciliationQueueSinks = [:]
        }
    }

    private func dispatchSyncQueriesReady() {
        let syncQueriesReadyPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyPayload)
    }

}

@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in newReconciliationQueues.values {
            guard let queue = queue as? Resettable else {
                continue
            }
            group.enter()
            DispatchQueue.global().async {
                queue.reset { group.leave() }
            }
        }
        group.wait()
        onComplete()
    }

}
