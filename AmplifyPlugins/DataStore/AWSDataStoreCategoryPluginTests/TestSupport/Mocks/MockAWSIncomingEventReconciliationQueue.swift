//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class MockAWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {
    static let factory: IncomingEventReconciliationQueueFactory = { modelTypes, api, storageAdapter in
        MockAWSIncomingEventReconciliationQueue(modelTypes: modelTypes, api: api, storageAdapter: storageAdapter)
    }
    let incomingEventSubject: PassthroughSubject<IncomingEventReconciliationQueueEvent, Error>

    static var lastInstance: MockAWSIncomingEventReconciliationQueue?
    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior,
         storageAdapter: StorageEngineAdapter) {
        self.incomingEventSubject = PassthroughSubject<IncomingEventReconciliationQueueEvent, Error>()
        updateLastInstance(instance: self)
    }

    func updateLastInstance(instance: MockAWSIncomingEventReconciliationQueue) {
        MockAWSIncomingEventReconciliationQueue.lastInstance = instance
    }

    func start() {
        incomingEventSubject.send(.started)
    }

    func pause() {
        incomingEventSubject.send(.paused)
    }

    func offer(_ remoteModel: MutationSync<AnyModel>) {
        //no-op for mock
    }

    func publisher() -> AnyPublisher<IncomingEventReconciliationQueueEvent, Error> {
        return incomingEventSubject.eraseToAnyPublisher()
    }

    static func mockSendCompletion(completion: Subscribers.Completion<Error>) {
        lastInstance?.incomingEventSubject.send(completion: completion)
    }
}
