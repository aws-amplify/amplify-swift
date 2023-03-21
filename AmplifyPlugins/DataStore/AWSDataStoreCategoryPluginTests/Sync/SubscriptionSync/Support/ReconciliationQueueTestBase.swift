//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class ReconciliationQueueTestBase: XCTestCase {

    var apiPlugin: MockAPICategoryPlugin!
    var authPlugin: MockAuthCategoryPlugin!
    var reconcileAndSaveQueue: ReconcileAndSaveQueue!
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var subscriptionEventsPublisher: MockIncomingSubscriptionEventPublisher!
    var subscriptionEventsSubject: PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>!
    var modelPredicate: QueryPredicate?

    override func setUp() {
        ModelRegistry.register(modelType: MockSynced.self)

        apiPlugin = MockAPICategoryPlugin()
        authPlugin = MockAuthCategoryPlugin()
        reconcileAndSaveQueue = ReconcileAndSaveQueue([MockSynced.schema])
        storageAdapter = MockSQLiteStorageEngineAdapter()
        subscriptionEventsPublisher = MockIncomingSubscriptionEventPublisher()
        subscriptionEventsSubject = subscriptionEventsPublisher.subject
    }

}

struct MockIncomingSubscriptionEventPublisher: IncomingSubscriptionEventPublisher {
    let subject = PassthroughSubject<IncomingSubscriptionEventPublisherEvent, DataStoreError>()

    var publisher: AnyPublisher<IncomingSubscriptionEventPublisherEvent, DataStoreError> {
        subject.eraseToAnyPublisher()
    }

    func cancel() {
        // no-op for mock
    }
}
