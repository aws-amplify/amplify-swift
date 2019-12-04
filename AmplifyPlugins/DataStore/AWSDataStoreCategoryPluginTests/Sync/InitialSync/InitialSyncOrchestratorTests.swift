//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class InitialSyncOrchestratorTests: SyncEngineTestBase {

    /// - Given: An InitialSyncOrchestrator with a model dependency graph
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It performs a sync query for each registered model
    func testShouldQueryModel() throws {
        tryOrFail {
            try setUpStorageAdapter()
            try setUpDataStore(modelRegistration: MockModelRegistration())
        }

        let syncStarted = expectation(description: "Sync started")
        let token = Amplify.Hub.listen(to: .dataStore,
                                       eventName: HubPayload.EventName.DataStore.syncStarted) { _ in
                                        syncStarted.fulfill()
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        tryOrFail {
            try startAmplify()
        }

        // Once we get the sync query, we have to wait for the "query" process to finish or else the test crashes
        // because it releases a waiting semaphore. While this test doesn't assert that completing the sync process
        // generates a "syncStarted" behavior, it does rely on it.
        wait(for: [syncStarted], timeout: 5.0)
        Amplify.Hub.removeListener(token)

    }

    /// - Given: An InitialSyncOrchestrator with a model dependency graph
    /// - When:
    ///    - The orchestrator starts up
    /// - Then:
    ///    - It queries models in dependency order, from "parent" to "child"
    func testShouldQueryInDependencyOrder() {
        XCTFail("Not yet implemented")
    }

}
