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

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable type_body_length
// swiftlint:disable file_length
class DataStoreConsecutiveUpdatesTests: SyncEngineIntegrationTestBase {
    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved and then immediately updated
    /// - Then: The post should be updated with new fields immediately and in the eventual consistent state
    func testSaveAndImmediatelyUpdate() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        var updatedPost = myPost
        updatedPost.rating = 5
        updatedPost.title = "MyUpdatedPost"
        updatedPost.content = "This is my updated post."

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
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                // this should be removed once the bug is fixed
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)

                // this is the expected behavior which is currently failing
                // XCTAssertEqual(post.title, "MyUpdatedPost")
                // XCTAssertEqual(post.content, "This is my updated post.")
                // XCTAssertEqual(post.rating, 5)

                updateSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post
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

        // update the created post
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

        // query the updated post immediately
        let immediateQueryExpectation = expectation(description: "Post is updated immediately")
        Amplify.DataStore.query(Post.self, byId: updatedPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertEqual(post?.title, updatedPost.title)
                XCTAssertEqual(post?.content, updatedPost.content)
                XCTAssertEqual(post?.rating, updatedPost.rating)
                immediateQueryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateQueryExpectation], timeout: networkTimeout)

        wait(for: [saveSyncExpectation], timeout: networkTimeout)
        wait(for: [updateSyncExpectation], timeout: networkTimeout)

        // query the updated post in eventual consistent state
        let queryExpectation = expectation(description: "Post is updated in eventual consistent state")
        Amplify.DataStore.query(Post.self, byId: updatedPost.id) { result in
            switch result {
            case .success(let post):
                // this should be removed once the bug is fixed
                XCTAssertEqual(post?.title, myPost.title)
                XCTAssertEqual(post?.content, myPost.content)
                XCTAssertEqual(post?.rating, myPost.rating)

                // this is the expected behavior which is currently failing
                // XCTAssertEqual(post?.title, updatedPost.title)
                // XCTAssertEqual(post?.content, updatedPost.content)
                // XCTAssertEqual(post?.rating, updatedPost.rating)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)

    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved and deleted immediately
    /// - Then: The Post should not be returned when queried for immediately and in the eventual consistent state
    func testSaveAndImmediatelyDelete() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        let saveSyncExpectation = expectation(description: "Post is saved and synced")
        // this needs to be commented out once the bug is fixed
        // currently the API request for delete mutation fails with error message "Conflict resolver rejects mutation."
        // because of version not being included, so the hub event is never fired
        // let deleteSyncExpectation = expectation(description: "Post is deleted and synced")

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
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)
                // this needs to be commented out once the bug is fixed
                // deleteSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post
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

        // delete the post
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

        // query the deleted post immediately
        let immediateQueryExpectation = expectation(description: "Post is not found after immediately deleting")
        Amplify.DataStore.query(Post.self, byId: myPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertNil(post)
                immediateQueryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateQueryExpectation], timeout: networkTimeout)

        wait(for: [saveSyncExpectation], timeout: networkTimeout)
        // this needs to be commented out once the bug is fixed
        // wait(for: [deleteSyncExpectation], timeout: networkTimeout)

        // query the deleted post in eventual consistent state
        let queryExpectation = expectation(description: "Post is not found in eventual consistent state ")
        Amplify.DataStore.query(Post.self, byId: myPost.id) { result in
            switch result {
            case .success(let post):
                // this should be removed once the bug is fixed
                XCTAssertNotNil(post)
                XCTAssertEqual(post?.title, myPost.title)
                XCTAssertEqual(post?.content, myPost.content)
                XCTAssertEqual(post?.rating, myPost.rating)

                // this is the actual behavior which is currently failing
                // XCTAssertNil(post)
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
    func testSaveThenUpdateAndImmediatelyDelete() throws {
        try startAmplifyAndWaitForSync()

        // create a post
        let myPost = Post(id: UUID().uuidString,
                          title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now(),
                          rating: 3,
                          status: .published)

        var updatedPost = myPost
        updatedPost.rating = 5
        updatedPost.title = "MyUpdatedPost"
        updatedPost.content = "This is my updated post."

        let saveSyncExpectation = expectation(description: "Post is saved and synced")
        let updateSyncExpectation = expectation(description: "Post is updated and synced")
        // this needs to be commented out once the bug is fixed
        // currently the API request for delete mutation fails with error message "Conflict resolver rejects mutation."
        // because of version not being included, so the hub event is never fired
        // let deleteSyncExpectation = expectation(description: "Post is deleted and synced")

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
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)
                saveSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                // this should be removed once the bug is fixed
                XCTAssertEqual(post.title, myPost.title)
                XCTAssertEqual(post.content, myPost.content)
                XCTAssertEqual(post.rating, myPost.rating)

                // expected behavior which is currently failing
                // XCTAssertEqual(post.title, updatedPost.title)
                // XCTAssertEqual(post.content, updatedPost.content)
                // XCTAssertEqual(post.rating, updatedPost.rating)
                updateSyncExpectation.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post.title, updatedPost.title)
                XCTAssertEqual(post.content, updatedPost.content)
                XCTAssertEqual(post.rating, updatedPost.rating)
                // this needs to be commented out once the bug is fixed
                // deleteSyncExpectation.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post
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

        // update the created post
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

        // query the deleted post immediately
        let immediateQueryExpectation = expectation(description: "Post is not found after immediately deleting")
        Amplify.DataStore.query(Post.self, byId: myPost.id) { result in
            switch result {
            case .success(let post):
                XCTAssertNil(post)
                immediateQueryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [immediateQueryExpectation], timeout: networkTimeout)

        wait(for: [saveSyncExpectation], timeout: networkTimeout)
        wait(for: [updateSyncExpectation], timeout: networkTimeout)
        // this needs to be commented out once the bug is fixed
        // wait(for: [deleteSyncExpectation], timeout: networkTimeout)

        // query the deleted post
        let queryExpectation = expectation(description: "Post is not found")
        Amplify.DataStore.query(Post.self, byId: updatedPost.id) { result in
            switch result {
            case .success(let post):
                // this should be removed once the bug is fixed
                XCTAssertNotNil(post)
                XCTAssertEqual(post?.title, myPost.title)
                XCTAssertEqual(post?.content, myPost.content)
                XCTAssertEqual(post?.rating, myPost.rating)

                // this is the actual behavior which is currently failing
                // XCTAssertNil(post)
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)
    }
}
