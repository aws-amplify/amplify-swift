//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// TODO: Delete mutation events from the database so that this can be run multiple times without having to remove the
// app from the device/simulator
class DataStoreHubTests: SyncEngineIntegrationTestBase {

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I create a new model
    /// - Then:
    ///    - The DataStore dispatches an event to Hub
    func testCreateDispatchesToHub() throws {
        try startAmplifyAndWaitForSync()

        let content = "Original post content as of \(Date())"

        let originalPost = Post(title: "Test post from integration test",
                                content: content)

        let saveSyncResultReceived = expectation(description: "Sync result from save received")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
            defer {
                saveSyncResultReceived.fulfill()
            }

            guard let anyPost = payload.data as? AnyModel else {
                XCTFail("Can't cast payload data to AnyModel: \(payload)")
                return
            }

            XCTAssertEqual(anyPost["id"] as? String, originalPost.id)
            XCTAssertEqual(anyPost["title"] as? String, originalPost.title)
            XCTAssertEqual(anyPost["content"] as? String, originalPost.content)

            Amplify.Hub.removeListener(token)
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Never registered listener for sync started")
            return
        }

        Amplify.DataStore.save(originalPost) { _ in }

        wait(for: [saveSyncResultReceived],
             timeout: networkTimeout)
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I update an existing model
    /// - Then:
    ///    - The DataStore dispatches an event to Hub
    func testUpdateDispatchesToHub() throws {
        try startAmplifyAndWaitForSync()

        let originalContent = "Original post content as of \(Date())"
        let newContent = "Updated post content as of \(Date())"

        let saveSyncResultReceived = expectation(description: "Sync result from save received")
        let updateSyncResultReceived = expectation(description: "Sync result from update received")
        let token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
            guard let anyPost = payload.data as? AnyModel else {
                XCTFail("Could not cast payload.data to AnyModel: \(String(describing: payload.data))")
                return
            }

            if anyPost["content"] as? String == originalContent {
                saveSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 1)
            } else if anyPost["content"] as? String == newContent {
                updateSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 2)
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        let originalPost = Post(title: "Test post from integration test",
                                content: originalContent)

        Amplify.DataStore.save(originalPost) { _ in }

        wait(for: [saveSyncResultReceived],
             timeout: networkTimeout)

        var updatedPost = originalPost
        updatedPost.content = newContent

        Amplify.DataStore.save(updatedPost) { _ in }

        wait(for: [updateSyncResultReceived],
             timeout: networkTimeout)

        Amplify.Hub.removeListener(token)
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I delete an existing model
    /// - Then:
    ///    - The DataStore dispatches an event to Hub
    func testDeleteDispatchesToHub() throws {
        let originalContent = "Original post content as of \(Date())"
        let newContent = "Updated post content as of \(Date())"

        let saveSyncResultReceived = expectation(description: "Sync result from save received")
        let deleteSyncResultReceived = expectation(description: "Sync result from delete received")
        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
            guard let anyPost = payload.data as? AnyModel else {
                XCTFail("Could not cast payload.data to AnyModel: \(String(describing: payload.data))")
                return
            }

            if anyPost["content"] as? String == originalContent {
                saveSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 1)
            } else if anyPost["content"] as? String == newContent {
                deleteSyncResultReceived.fulfill()
                XCTAssertEqual(anyPost["_version"] as? Int, 2)
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        let originalPost = Post(title: "Test post from integration test",
                                content: originalContent)

        Amplify.DataStore.save(originalPost) { _ in }

        wait(for: [saveSyncResultReceived],
             timeout: networkTimeout)

        Amplify.DataStore.delete(originalPost) { _ in }

        wait(for: [deleteSyncResultReceived],
             timeout: networkTimeout)

        Amplify.Hub.removeListener(token)
    }

}
