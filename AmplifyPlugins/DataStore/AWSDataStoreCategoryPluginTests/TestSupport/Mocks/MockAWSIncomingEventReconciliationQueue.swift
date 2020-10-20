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
    static let factory: IncomingEventReconciliationQueueFactory = { modelTypes, api, storageAdapter, auth, _ in
        MockAWSIncomingEventReconciliationQueue(modelTypes: modelTypes,
                                                api: api,
                                                storageAdapter: storageAdapter,
                                                auth: auth)
    }
    let incomingEventSubject: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return incomingEventSubject.eraseToAnyPublisher()
    }

    static var lastInstance = AtomicValue<MockAWSIncomingEventReconciliationQueue?>(initialValue: nil)
    init(modelTypes: [Model.Type],
         api: APICategoryGraphQLBehavior?,
         storageAdapter: StorageEngineAdapter?,
         auth: AuthCategoryBehavior?) {
        self.incomingEventSubject = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        updateLastInstance(instance: self)
    }

    func updateLastInstance(instance: MockAWSIncomingEventReconciliationQueue) {
        MockAWSIncomingEventReconciliationQueue.lastInstance.set(instance)
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

    static func mockSendCompletion(completion: Subscribers.Completion<DataStoreError>) {
        lastInstance.get()?.incomingEventSubject.send(completion: completion)
    }

    static func mockSend(event: IncomingEventReconciliationQueueEvent) {
        lastInstance.get()?.incomingEventSubject.send(event)
    }

    func cancel() {
        //no-op for mock
    }
}
