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

class DataStoreConsecutiveUpdatesTests: SyncEngineIntegrationTestBase {

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved with sync complete and deleted immediately
    /// - Then: The Post should not be returned when queried for
    func testSaveAndImmediateDelete() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        let saveSyncExpectation = expectation(description: "Post is saved and synced")
        let deleteSyncExpectation = expectation(description: "Post is deleted and synced")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent
            else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post,
                  post.id == myPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 3)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 3)
                deleteSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post and wait for it to sync
        let immediateSaveExpectation = expectation(description: "Post is saved")
        Amplify.DataStore.save(myPost) { result in
            switch result {
            case .success:
                immediateSaveExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateSaveExpectation], timeout: networkTimeout)
        wait(for: [saveSyncExpectation], timeout: networkTimeout)

        // delete the updated post
        let immediateDeleteExpectation = expectation(description: "Post is immediately deleted")
        Amplify.DataStore.delete(myPost) { result in
            switch result {
            case .success:
                immediateDeleteExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateDeleteExpectation], timeout: networkTimeout)
        wait(for: [deleteSyncExpectation], timeout: networkTimeout)

        // query the deleted post
        let queryExpectation = expectation(description: "Post is not found")
        Amplify.DataStore.query(Post.self, byId: myPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertNil(post)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)

    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved with sync complete, updated and deleted immediately
    /// - Then: The Post should not be returned when queried for
    func testSaveUpdateAndImmediateDelete() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        let saveSyncExpectation = expectation(description: "Post is saved and synced")
        let updateSyncExpectation = expectation(description: "Post is updated and synced")
        let deleteSyncExpectation = expectation(description: "Post is deleted and synced")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent
            else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post,
                  post.id == myPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 3)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 5)
                updateSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 5)
                deleteSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post and wait for it to sync
        let immediateSaveExpectation = expectation(description: "Post is saved")
        Amplify.DataStore.save(myPost) { result in
            switch result {
            case .success:
                immediateSaveExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateSaveExpectation], timeout: networkTimeout)
        wait(for: [saveSyncExpectation], timeout: networkTimeout)

        // update the created post
        var updatedPost = myPost
        updatedPost.rating = 5
        let immediateUpdateExpectation = expectation(description: "Post is updated")
        Amplify.DataStore.save(updatedPost) { result in
            switch result {
            case .success:
                immediateUpdateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateUpdateExpectation], timeout: networkTimeout)
        wait(for: [updateSyncExpectation], timeout: networkTimeout)

        // delete the updated post
        let immediateDeleteExpectation = expectation(description: "Post is immediately deleted")
        Amplify.DataStore.delete(updatedPost) { result in
            switch result {
            case .success:
                immediateDeleteExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateDeleteExpectation], timeout: networkTimeout)
        wait(for: [deleteSyncExpectation], timeout: networkTimeout)

        // query the deleted post
        let queryExpectation = expectation(description: "Post is not found")
        Amplify.DataStore.query(Post.self, byId: updatedPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertNil(post)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)

    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved with sync complete and updated
    /// - Then: The post should be updated with new fields
    func testSaveAndUpdate() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        let saveSyncExpectation = expectation(description: "Post is saved and synced")
        let updateSyncExpectation = expectation(description: "Post is updated and synced")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent
            else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post,
                  post.id == myPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post.title, "MyPost")
                XCTAssertEqual(post.content, "This is my post.")
                XCTAssertEqual(post.rating, 3)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                XCTAssertEqual(post.title, "MyUpdatedPost")
                XCTAssertEqual(post.content, "This is my updated post.")
                XCTAssertEqual(post.rating, 5)
                updateSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post and wait for it to sync
        let immediateSaveExpectation = expectation(description: "Post is saved")
        Amplify.DataStore.save(myPost) { result in
            switch result {
            case .success:
                immediateSaveExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateSaveExpectation], timeout: networkTimeout)
        wait(for: [saveSyncExpectation], timeout: networkTimeout)

        // update the created post
        var updatedPost = myPost
        updatedPost.rating = 5
        updatedPost.title = "MyUpdatedPost"
        updatedPost.content = "This is my updated post."
        let immediateUpdateExpectation = expectation(description: "Post is updated")
        Amplify.DataStore.save(updatedPost) { result in
            switch result {
            case .success:
                immediateUpdateExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateUpdateExpectation], timeout: networkTimeout)
        wait(for: [updateSyncExpectation], timeout: networkTimeout)

        // query the deleted post
        let queryExpectation = expectation(description: "Post is not found")
        Amplify.DataStore.query(Post.self, byId: updatedPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertEqual(post?.title, "MyUpdatedPost")
                XCTAssertEqual(post?.content, "This is my updated post.")
                XCTAssertEqual(post?.rating, 5)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)

    }

}
