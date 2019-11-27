//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class OutgoingMutationQueueTests: XCTestCase {

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.save()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueStoresSaveEvents() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I invoke DataStore.delete()
    /// - Then:
    ///    - The mutation queue writes events
    func testMutationQueueStoresDeleteEvents() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I restart the app
    /// - Then:
    ///    - The mutation queue processes previously loaded events
    func testMutationQueueLoadsPendingMutations() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation queue deletes the event from its persistent store
    func testMutationQueueDequeuesSavedEvents() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A sync-configured DataStore
    /// - When:
    ///    - I successfully process a mutation
    /// - Then:
    ///    - The mutation listener is unsubscribed from Hub
    func testLocalMutationUnsubcsribesFromCloud() {
        XCTFail("Not yet implemented")
    }

}
