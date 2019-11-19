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
    typealias Factory = (StorageEngineBehavior) -> CloudSyncEngineBehavior

    /// Loads previously queued mutations and begins sending them to the cloud API
    func start()

    /// Submits a new mutation for synchronization to the cloud
    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError>
}

@available(iOS 13.0, *)
class CloudSyncEngine: CloudSyncEngineBehavior {

    let mutationQueue: OutgoingMutationQueue
    let subscriber: SyncEngineMutationSubscriber

    init(storageEngine: StorageEngineBehavior,
         api: APICategoryGraphQLBehavior = Amplify.API) {
        self.mutationQueue = OutgoingMutationQueue(storageEngine: storageEngine)
        self.subscriber = SyncEngineMutationSubscriber(api: api)
    }

    func start() {
        mutationQueue.subscribe(subscriber: subscriber)
    }

    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        return mutationQueue.enqueue(event: mutationEvent)
    }
}
