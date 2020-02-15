//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
    ([Model.Type], APICategoryGraphQLBehavior, StorageEngineAdapter) -> IncomingEventReconciliationQueue

@available(iOS 13.0, *)
final class AWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    static let factory: IncomingEventReconciliationQueueFactory = { modelTypes, api, storageAdapter in
        AWSIncomingEventReconciliationQueue(modelTypes: modelTypes, api: api, storageAdapter: storageAdapter)
    }
    private var modelReconciliationQueueSinks: [String: AnyCancellable]

    private let eventReconciliationQueueTopic: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return eventReconciliationQueueTopic.eraseToAnyPublisher()
    }

    private var reconciliationQueues: [String: ModelReconciliationQueue]

    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter) {
        self.modelReconciliationQueueSinks = [:]
        self.eventReconciliationQueueTopic = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        self.reconciliationQueues = [:]

        for modelType in modelTypes {
            let modelName = modelType.modelName
            let queue = AWSModelReconciliationQueue(modelType: modelType,
                                                    storageAdapter: storageAdapter,
                                                    api: api)
            guard reconciliationQueues[modelName] == nil else {
                Amplify.DataStore.log
                    .warn("Duplicate model name found: \(modelName), not subscribing")
                continue
            }
            reconciliationQueues[modelName] = queue
            let modelReconciliationQueueSink = queue.publisher.sink(receiveCompletion: onReceiveCompletion(completed:),
                                                                    receiveValue: onRecieveValue(receiveValue:))
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

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        guard let queue = reconciliationQueues[remoteModel.model.modelName] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModel)
    }

    private func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        switch completed {
        case .failure(let error):
            eventReconciliationQueueTopic.send(completion: .failure(error))
        case .finished:
            eventReconciliationQueueTopic.send(completion: .finished)
        }
    }

    private func onRecieveValue(receiveValue: ModelReconciliationQueueEvent) {
        if case .mutationEvent(let event) = receiveValue {
            self.eventReconciliationQueueTopic.send(.mutationEvent(event))
        }
    }

    func cancel() {
        modelReconciliationQueueSinks.values.forEach { $0.cancel() }
        reconciliationQueues.values.forEach { $0.cancel()}
        reconciliationQueues = [:]
        modelReconciliationQueueSinks = [:]
    }
}

@available(iOS 13.0, *)
extension AWSIncomingEventReconciliationQueue: Resettable {

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in reconciliationQueues.values {
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
