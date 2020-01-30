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

    private let incomingEventReconciliationQueueTopic: PassthroughSubject<IncomingEventReconciliationQueueEvent, Error>
    private var incomingEventReconciliationQueueCancellable = [String: AnyCancellable]()

    private var reconciliationQueues = [String: ModelReconciliationQueue]()

    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter) {

        self.incomingEventReconciliationQueueTopic = PassthroughSubject<IncomingEventReconciliationQueueEvent, Error>()
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

            let cancellable = queue.publisher().sink(receiveCompletion: { completed in
                switch completed {
                case .failure(let error):
                    self.incomingEventReconciliationQueueTopic.send(completion: .failure(error))
                case .finished:
                    self.incomingEventReconciliationQueueTopic.send(completion: .finished)
                }
            }, receiveValue: { _ in
                //no-op
            })
            incomingEventReconciliationQueueCancellable[modelName] = cancellable
        }
    }

    func start() {
        reconciliationQueues.values.forEach { $0.start() }
        incomingEventReconciliationQueueTopic.send(.started)
    }

    func pause() {
        reconciliationQueues.values.forEach { $0.pause() }
        incomingEventReconciliationQueueTopic.send(.paused)
    }

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        guard let queue = reconciliationQueues[remoteModel.model.modelName] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModel)
    }

    func publisher() -> AnyPublisher<IncomingEventReconciliationQueueEvent, Error> {
        incomingEventReconciliationQueueTopic.eraseToAnyPublisher()
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
