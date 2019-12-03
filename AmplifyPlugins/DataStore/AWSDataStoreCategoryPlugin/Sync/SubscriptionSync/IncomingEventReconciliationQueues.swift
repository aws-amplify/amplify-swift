//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

/// A collection of queues, one per syncable model type, that reconcile all incoming events for a model: responses
/// from locally-sourced mutations, and subscription events for create, update, and delete events initiated by remote
/// systems.
@available(iOS 13.0, *)
final class IncomingEventReconciliationQueues {

    private var reconciliationQueues = [String: ReconciliationQueue]()

    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter) {
        for modelType in modelTypes {
            let modelName = modelType.modelName
            let queue = ReconciliationQueue(modelType: modelType, storageAdapter: storageAdapter, api: api)
            guard reconciliationQueues[modelName] == nil else {
                Amplify.DataStore.log
                    .warn("Duplicate model name found: \(modelName), not subscribing")
                continue
            }
            reconciliationQueues[modelName] = queue
        }
    }

    func start() {
        reconciliationQueues.values.forEach { $0.start() }
    }

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        guard let queue = reconciliationQueues[remoteModel.model.modelName] else {
            // TODO: Error handling
            return
        }

        queue.enqueue(remoteModel)
    }

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()
        for queue in reconciliationQueues.values {
            group.enter()
            DispatchQueue.global().async {
                queue.reset { group.leave() }
            }
        }
        group.wait()
        onComplete()
    }
}
