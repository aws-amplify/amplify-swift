//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
    var storageAdapter: MockSQLiteStorageEngineAdapter!
    var subscriptionEventsPublisher: MockIncomingSubscriptionEventPublisher!
    var subscriptionEventsSubject: PassthroughSubject<MutationSync<AnyModel>, DataStoreError>!

    override func setUp() {
        ModelRegistry.register(modelType: MockSynced.self)

        apiPlugin = MockAPICategoryPlugin()

        storageAdapter = MockSQLiteStorageEngineAdapter()
        subscriptionEventsPublisher = MockIncomingSubscriptionEventPublisher()
        subscriptionEventsSubject = subscriptionEventsPublisher.subject
    }

}

struct MockIncomingSubscriptionEventPublisher: IncomingSubscriptionEventPublisher {
    let subject = PassthroughSubject<MutationSync<AnyModel>, DataStoreError>()

    var publisher: AnyPublisher<MutationSync<AnyModel>, DataStoreError> {
        subject.eraseToAnyPublisher()
    }
}
