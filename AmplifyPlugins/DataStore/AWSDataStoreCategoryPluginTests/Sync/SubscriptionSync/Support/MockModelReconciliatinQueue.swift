//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin
class MockModelReconciliationQueue: ModelReconciliationQueue {

    public static var mockModelReconciliationQueues: [String: MockModelReconciliationQueue] = [:]
    private let modelType: Model.Type
    let modelReconciliationQueueSubject: PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>
    var publisher: AnyPublisher<ModelReconciliationQueueEvent, DataStoreError> {
        return modelReconciliationQueueSubject.eraseToAnyPublisher()
    }

    init(modelType: Model.Type,
         storageAdapter: StorageEngineAdapter?,
         api: APICategoryGraphQLBehavior,
         auth: AuthCategoryBehavior?,
         incomingSubscriptionEvents: IncomingSubscriptionEventPublisher? = nil) {
        self.modelReconciliationQueueSubject = PassthroughSubject<ModelReconciliationQueueEvent, DataStoreError>()
        self.modelType = modelType
        MockModelReconciliationQueue.mockModelReconciliationQueues[modelType.modelName] = self
    }

    func start() {
        //no-op
    }
    func pause() {
        //no-op
    }

    func cancel() {
        //no-op
    }

    func enqueue(_ remoteModel: MutationSync<AnyModel>) {
        //no-op
    }

    static func reset() {
        MockModelReconciliationQueue.mockModelReconciliationQueues = [:]
    }
}
