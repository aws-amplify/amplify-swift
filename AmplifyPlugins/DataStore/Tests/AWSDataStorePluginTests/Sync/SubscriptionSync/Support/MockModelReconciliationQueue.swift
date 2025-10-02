//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

class MockModelReconciliationQueue: ModelReconciliationQueue {

    static var mockModelReconciliationQueues: [String: MockModelReconciliationQueue] = [:]

    private let modelSchema: ModelSchema
    let modelReconciliationQueueSubject: PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> {
        return modelReconciliationQueueSubject.eraseToAnyPublisher()
    }

    init(
        modelSchema: ModelSchema,
        storageAdapter: StorageEngineAdapter?,
        api: APICategoryGraphQLBehavior,
        reconcileAndSaveQueue: ReconcileAndSaveOperationQueue,
        modelPredicate: QueryPredicate?,
        auth: AuthCategoryBehavior?,
        authModeStrategy: AuthModeStrategy,
        incomingSubscriptionEvents: IncomingSubscriptionEventPublisher? = nil
    ) {
        self.modelReconciliationQueueSubject = PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>()
        self.modelSchema = modelSchema
        MockModelReconciliationQueue.mockModelReconciliationQueues[modelSchema.name] = self
    }

    func start() {
        // no-op
    }
    func pause() {
        // no-op
    }

    func cancel() {
        // no-op
    }

    func enqueue(_ remoteModels: [MutationSync<AnyModel>]) {
        // no-op
    }

    static func reset() {
        MockModelReconciliationQueue.mockModelReconciliationQueues = [:]
    }
}
