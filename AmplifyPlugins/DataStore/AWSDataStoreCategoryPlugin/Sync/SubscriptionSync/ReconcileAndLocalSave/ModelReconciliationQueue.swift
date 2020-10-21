//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

enum ModelConnectionDisconnectedReason {
    case unauthorized
}

enum ModelReconciliationQueueEvent {
    case started
    case paused
    case connected(modelName: String)
    case disconnected(modelName: String, reason: ModelConnectionDisconnectedReason)
    case mutationEvent(MutationEvent)
    case mutationEventDropped(modelName: String)
}

@available(iOS 13.0, *)
protocol ModelReconciliationQueue {
    func start()
    func pause()
    func cancel()
    func enqueue(_ remoteModel: MutationSync<AnyModel>)
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> { get }
}
