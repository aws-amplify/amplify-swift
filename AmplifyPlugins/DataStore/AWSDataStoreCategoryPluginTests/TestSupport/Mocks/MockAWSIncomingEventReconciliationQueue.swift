//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class MockAWSIncomingEventReconciliationQueue: IncomingEventReconciliationQueue {

    let syncableModelSchemas: [ModelSchema]

    static let factory: IncomingEventReconciliationQueueFactory = { syncableModelSchemas, _  in
        MockAWSIncomingEventReconciliationQueue(syncableModelSchemas: syncableModelSchemas)
    }
    let incomingEventSubject: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return incomingEventSubject.eraseToAnyPublisher()
    }

    static var lastInstance = AtomicValue<MockAWSIncomingEventReconciliationQueue?>(initialValue: nil)
    init(syncableModelSchemas: [ModelSchema]) {
        self.syncableModelSchemas = syncableModelSchemas
        self.incomingEventSubject = PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>()
        updateLastInstance(instance: self)
    }

    func updateLastInstance(instance: MockAWSIncomingEventReconciliationQueue) {
        MockAWSIncomingEventReconciliationQueue.lastInstance.set(instance)
    }

    func initializeSubscriptions(syncExpressions: [DataStoreSyncExpression],
                                 authModeStrategy: AuthModeStrategy,
                                 storageAdapter: StorageEngineAdapter,
                                 api: APICategoryGraphQLBehavior,
                                 auth: AuthCategoryBehavior?) {
        // no-op for mock
    }

    func start() {
        incomingEventSubject.send(.started)
    }

    func pause() {
        incomingEventSubject.send(.paused)
    }

    func offer(_ remoteModels: [MutationSync<AnyModel>], modelName: String) {
        // no-op for mock
    }

    static func mockSendCompletion(completion: Subscribers.Completion<DataStoreError>) {
        lastInstance.get()?.incomingEventSubject.send(completion: completion)
    }

    static func mockSend(event: IncomingEventReconciliationQueueEvent) {
        lastInstance.get()?.incomingEventSubject.send(event)
    }

    func cancel() {
        // no-op for mock
    }
}
