//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

enum ModelReconciliationQueueEvent {
    case started
    case paused
    case finished
    case connected(String)
    case mutationEvent(MutationEvent)
}

@available(iOS 13.0, *)
protocol ModelReconciliationQueue {
    func start()
    func pause()
    func cancel()
    func enqueue(_ remoteModel: MutationSync<AnyModel>)
    var isFullSync: Bool { get set }
    var count: Int { get set }
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> { get }
}
