//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

import AWSDataStoreCategoryPlugin

/// Tests that DataStore invokes proper API methods to fulfill cloud sync
class CloudSyncTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
    }

    /// Tests that DataStore subscribes at startup. Test knows about the internals of the subscription--e.g., that
    /// DataStore sends 3 subscriptions for each model: one each for create, update, and delete.
    ///
    /// - Given: Amplify configured with an API
    /// - When:
    ///    - Amplify starts up
    /// - Then:
    ///    - The DataStore category starts subscriptions for each model
    func testDataStoreSubscribesAtStartup() {
        XCTFail("Not yet implemented")
    }

    /// - Given: A configured Amplify DataStore
    /// - When:
    ///    - I invoke `DataStore.subscribe(to:)`
    /// - Then:
    ///    - I receive mutation events for that model
    func testSimpleSubscribe() {
        XCTFail("Not yet implemented")
    }

}
