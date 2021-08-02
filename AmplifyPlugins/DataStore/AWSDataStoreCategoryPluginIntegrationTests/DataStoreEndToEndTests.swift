//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

@available(iOS 13.0, *)
class DataStoreEndToEndTests: SyncEngineIntegrationTestBase {

    func testCreateMutateDelete() throws {
        try startAmplifyAndWaitForSync()

        let date = Temporal.DateTime.now()

        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")
        let deleteReceived = expectation(description: "Delete notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)

        Amplify.DataStore.delete(updatedPost) { _ in }

        wait(for: [deleteReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - attempt to update the existing post with a condition that matches existing data
    /// - Then:
    ///    - the update with condition that matches existing data will be applied and returned.
    func testCreateThenMutateWithCondition() throws {
        try startAmplifyAndWaitForSync()

        let post = Post.keys
        let date = Temporal.DateTime.now()
        let title = "This is a new post I created"
        let newPost = Post(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        var updatedPost = newPost
            updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost, where: post.title == title) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - update the post's content directly using `storageAdapter` to persist the update in local store
    ///    - save the post with the condition that matches the updated content, bypassing local store validation
    /// - Then:
    ///    - the post is first only updated on local store is not sync to the remote
    ///    - the save with condition reaches the remote and fails with conditional save failed
    func testCreateThenMutateWithConditionFailOnSync() throws {
        try startAmplifyAndWaitForSync()

        let post = Post.keys
        let date = Temporal.DateTime.now()
        let title = "This is a new post I created"
        let newPost = Post(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date.iso8601String)",
            createdAt: date)

        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateLocalSuccess = expectation(description: "Update local successful")
        let conditionalReceived = expectation(description: "Conditional save failed received")

        let syncReceivedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncReceived)
        let conditionalSaveFailedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.conditionalSaveFailed)
        let filters = HubFilters.any(filters: syncReceivedFilter, conditionalSaveFailedFilter)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filters) { payload in
            guard let mutationEvent = payload.data as? MutationEvent
                else {
                    XCTFail("Can't cast payload as mutation event")
                    return
            }

            // This check is to protect against stray events being processed after the test has completed,
            // and it shouldn't be construed as a pattern necessary for production applications.
            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if payload.eventName == HubPayload.EventName.DataStore.syncReceived {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
            } else if payload.eventName == HubPayload.EventName.DataStore.conditionalSaveFailed {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.title, updatedPost.title)
                    XCTAssertEqual(mutationEvent.version, 1)
                    conditionalReceived.fulfill()
                    return
                }
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        storageAdapter.save(updatedPost) { result in
            switch result {
            case .success(let post):
                print("Saved post \(post)")
                updateLocalSuccess.fulfill()
            case .failure(let error):
                XCTFail("Failed to save post directly to local store \(error)")
            }
        }

        wait(for: [updateLocalSuccess], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost, where: post.content == updatedPost.content) { _ in }

        wait(for: [conditionalReceived], timeout: networkTimeout)
    }

    /// Ensure DataStore.stop followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testStopStart() throws {
        try startAmplifyAndWaitForSync()
        let stopStartSuccess = expectation(description: "stop then start successful")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        stopStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopStartSuccess], timeout: networkTimeout)
        try validateSavePost()

    }

    /// Ensure the DataStore is automatically started when querying for the first time
    ///
    /// - Given: DataStore is configured but not started
    /// - When:
    ///   - I call DataStore.query()
    /// - Then:
    ///   - DataStore is automatically started
    func testQueryImplicitlyStarts() throws {
        let dataStoreStarted = expectation(description: "dataStoreStarted")
        let sink = Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in dataStoreStarted.fulfill() }

        let amplifyStarted = expectation(description: "amplifyStarted")
        try startAmplify {
            amplifyStarted.fulfill()
        }
        wait(for: [amplifyStarted], timeout: 1.0)

        // We expect the query to complete, but not to return a value. Thus, we'll ignore the error
        let queryCompleted = expectation(description: "queryCompleted")
        Amplify.DataStore.query(Post.self, byId: "123") { _ in queryCompleted.fulfill() }

        wait(for: [dataStoreStarted, queryCompleted], timeout: networkTimeout)
        sink.cancel()
    }

    /// Ensure DataStore.clear followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start in the completion of the clear
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testClearStart() throws {
        try startAmplifyAndWaitForSync()
        let clearStartSuccess = expectation(description: "clear then start successful")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        clearStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [clearStartSuccess], timeout: networkTimeout)
        try validateSavePost()
    }

    // MARK: - Helpers

    func validateSavePost() throws {
        let date = Temporal.DateTime.now()
        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)
        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }
        wait(for: [createReceived], timeout: networkTimeout)
    }
}
