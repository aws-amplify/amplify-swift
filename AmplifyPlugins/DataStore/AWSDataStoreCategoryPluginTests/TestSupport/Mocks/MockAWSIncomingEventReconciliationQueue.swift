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
    // swiftlint:disable:next line_length
    static let factory: IncomingEventReconciliationQueueFactory = { modelSchemas, api, storageAdapter, syncExpressions, auth, _, _  in
        MockAWSIncomingEventReconciliationQueue(modelSchemas: modelSchemas,
                                                api: api,
                                                storageAdapter: storageAdapter,
                                                syncExpressions: syncExpressions,
                                                auth: auth)
    }
    let incomingEventSubject: PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return incomingEventSubject.eraseToAnyPublisher()
    }

    static var lastInstance = AtomicValue<MockAWSIncomingEventReconciliationQueue?>(initialValue: nil)
    init(modelSchemas: [ModelSchema],
         api: APICategoryGraphQLBehavior?,
         storageAdapter: StorageEngineAdapter?,
         syncExpressions: [DataStoreSyncExpression],
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

    func offer(_ remoteModels: [MutationSync<AnyModel>], modelName: ModelName) {
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
