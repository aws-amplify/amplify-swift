//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore

@testable import Amplify
@testable import AWSDataStorePlugin

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable type_body_length
class DataStoreConsecutiveUpdatesTests: SyncEngineIntegrationTestBase {
    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved and then immediately updated
    /// - Then: The post should be updated with new fields immediately and in the eventual consistent state
    func testSaveAndImmediatelyUpdate() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let newPost = Post(title: "MyPost",
                          content: "This is my post.",
                          createdAt: .now(),
                          rating: 3,
                          status: .published)

        var updatedPost = newPost
        updatedPost.rating = 5
        updatedPost.title = "MyUpdatedPost"
        updatedPost.content = "This is my updated post."

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let updateSyncReceived = expectation(description: "Received update mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post, newPost)
                XCTAssertEqual(mutationEvent.version, 1)
                saveSyncReceived.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                XCTAssertEqual(post, updatedPost)
                XCTAssertEqual(mutationEvent.version, 2)
                updateSyncReceived.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveAndImmediatelyUpdate = expectation(description: "Post is saved and then immediately updated")
        Amplify.DataStore.save(newPost) { result in
            switch result {
            case .success:
                Amplify.DataStore.save(updatedPost) { result in
                    switch result {
                    case .success:
                        saveAndImmediatelyUpdate.fulfill()
                    case .failure(let error):
                        XCTFail("Error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [saveAndImmediatelyUpdate], timeout: networkTimeout)

        // query the updated post immediately
        guard let queryResult = queryPost(byId: updatedPost.id) else {
            XCTFail("Post should be available after update")
            return
        }
        XCTAssertEqual(queryResult, updatedPost)

        wait(for: [saveSyncReceived, updateSyncReceived], timeout: networkTimeout)

        // query the updated post in eventual consistent state
        guard let queryResultAfterSync = queryPost(byId: updatedPost.id) else {
            XCTFail("Post should be available after update and sync")
            return
        }

        XCTAssertEqual(queryResultAfterSync, updatedPost)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let apiQuerySuccess = expectation(description: "API query is successful")
        Amplify.API.query(request: queryRequest) { result in
            switch result {
            case .success(let mutationSyncResult):
                switch mutationSyncResult {
                case .success(let data):
                    guard let post = data else {
                        XCTFail("Failed to get data")
                        return
                    }

                    XCTAssertEqual(post.model["title"] as? String, updatedPost.title)
                    XCTAssertEqual(post.model["content"] as? String, updatedPost.content)
                    XCTAssertEqual(post.model["rating"] as? Double, updatedPost.rating)
                    XCTAssertEqual(post.syncMetadata.version, 2)
                    apiQuerySuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [apiQuerySuccess], timeout: networkTimeout)
    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved and deleted immediately
    /// - Then: The Post should not be returned when queried for immediately and in the eventual consistent state
    func testSaveAndImmediatelyDelete() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let newPost = Post(title: "MyPost",
                          content: "This is my post.",
                          createdAt: .now(),
                          rating: 3,
                          status: .published)

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let deleteSyncReceived = expectation(description: "Received delete mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post, newPost)
                XCTAssertEqual(mutationEvent.version, 1)
                saveSyncReceived.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post, newPost)
                XCTAssertEqual(mutationEvent.version, 2)
                deleteSyncReceived.fulfill()
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveAndImmediatelyDelete = expectation(description: "Post is saved and then immediately deleted")
        Amplify.DataStore.save(newPost) { result in
            switch result {
            case .success:
                Amplify.DataStore.delete(newPost) { result in
                    switch result {
                    case .success:
                        saveAndImmediatelyDelete.fulfill()
                    case .failure(let error):
                        XCTFail("Error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [saveAndImmediatelyDelete], timeout: networkTimeout)

        // query the deleted post immediately
        let queryResult = queryPost(byId: newPost.id)
        XCTAssertNil(queryResult)

        wait(for: [saveSyncReceived, deleteSyncReceived], timeout: networkTimeout)

        // query the deleted post in eventual consistent state
        let queryResultAfterSync = queryPost(byId: newPost.id)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: newPost.modelName, byId: newPost.id)
        let apiQuerySuccess = expectation(description: "API query is successful")
        Amplify.API.query(request: queryRequest) { result in
            switch result {
            case .success(let mutationSyncResult):
                switch mutationSyncResult {
                case .success(let data):
                    guard let post = data else {
                        XCTFail("Failed to get data")
                        return
                    }

                    XCTAssertEqual(post.model["title"] as? String, newPost.title)
                    XCTAssertEqual(post.model["content"] as? String, newPost.content)
                    XCTAssertEqual(post.model["rating"] as? Double, newPost.rating)
                    XCTAssertTrue(post.syncMetadata.deleted)
                    XCTAssertEqual(post.syncMetadata.version, 2)
                    apiQuerySuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [apiQuerySuccess], timeout: networkTimeout)
    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved with sync complete, updated and deleted immediately
    /// - Then: The Post should not be returned when queried for
    func testSaveThenUpdateAndImmediatelyDelete() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let newPost = Post(title: "MyPost",
                          content: "This is my post.",
                          createdAt: .now(),
                          rating: 3,
                          status: .published)

        var updatedPost = newPost
        updatedPost.rating = 5
        updatedPost.title = "MyUpdatedPost"
        updatedPost.content = "This is my updated post."

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let updateSyncReceived = expectation(description: "Received update mutation event on subscription for Post")
        let deleteSyncReceived = expectation(description: "Received delete mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post, newPost)
                XCTAssertEqual(mutationEvent.version, 1)
                saveSyncReceived.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                XCTAssertEqual(post, updatedPost)
                XCTAssertEqual(mutationEvent.version, 2)
                updateSyncReceived.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post, updatedPost)
                deleteSyncReceived.fulfill()
                XCTAssertEqual(mutationEvent.version, 3)
                return
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post, update and delete immediately
        let saveCompleted = expectation(description: "Save is completed")
        Amplify.DataStore.save(newPost) { result in
            switch result {
            case .success:
                saveCompleted.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [saveCompleted, saveSyncReceived], timeout: networkTimeout)

        let updateAndImmediatelyDelete =
            expectation(description: "Post is updated and deleted immediately")
        Amplify.DataStore.save(updatedPost) { result in
            switch result {
            case .success:
                Amplify.DataStore.delete(updatedPost) { result in
                    switch result {
                    case .success:
                        updateAndImmediatelyDelete.fulfill()
                    case .failure(let error):
                        XCTFail("Error: \(error)")
                    }
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }

        wait(for: [updateAndImmediatelyDelete], timeout: networkTimeout)

        // query the deleted post immediately
        let queryResult = queryPost(byId: newPost.id)
        XCTAssertNil(queryResult)

        wait(for: [updateSyncReceived, deleteSyncReceived], timeout: networkTimeout)

        // query the deleted post
        let queryResultAfterSync = queryPost(byId: updatedPost.id)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let apiQuerySuccess = expectation(description: "API query is successful")
        Amplify.API.query(request: queryRequest) { result in
            switch result {
            case .success(let mutationSyncResult):
                switch mutationSyncResult {
                case .success(let data):
                    guard let post = data else {
                        XCTFail("Failed to get data")
                        return
                    }

                    XCTAssertEqual(post.model["title"] as? String, updatedPost.title)
                    XCTAssertEqual(post.model["content"] as? String, updatedPost.content)
                    XCTAssertEqual(post.model["rating"] as? Double, updatedPost.rating)

                    XCTAssertTrue(post.syncMetadata.deleted)
                    XCTAssertEqual(post.syncMetadata.version, 3)
                    apiQuerySuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [apiQuerySuccess], timeout: networkTimeout)
    }

    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved with sync complete, then it is updated 10 times
    /// - Then: The Post should be updated with new fields
    func testSaveThenMultipleUpdate() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let newPost = Post(title: "MyPost",
                          content: "This is my post.",
                          createdAt: .now(),
                          rating: 3,
                          status: .published)
        var updatedPost = newPost
        let updatedPostDefaultTitle = "MyUpdatedPost"
        let updateCount = 10

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let updateSyncReceived = expectation(description: "Received update mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                XCTAssertEqual(post, newPost)
                XCTAssertEqual(mutationEvent.version, 1)
                saveSyncReceived.fulfill()
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                if post.title == updatedPostDefaultTitle + String(updateCount) {
                    updateSyncReceived.fulfill()
                    return
                }
            }

        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        let saveCompleted = expectation(description: "Save is completed")
        Amplify.DataStore.save(newPost) { result in
            switch result {
            case .success:
                saveCompleted.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [saveCompleted, saveSyncReceived], timeout: networkTimeout)

        for index in 1 ... updateCount {
            updatedPost.title = updatedPostDefaultTitle + String(index)
            let saveExpectation = expectation(description: "Save \(index) is successful")
            Amplify.DataStore.save(updatedPost) { result in
                switch result {
                case .success:
                    saveExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
            }
            wait(for: [saveExpectation], timeout: networkTimeout)
        }

        wait(for: [updateSyncReceived], timeout: networkTimeout)

        // query the updated post in eventual consistent state
        guard let queryResultAfterSync = queryPost(byId: updatedPost.id) else {
            XCTFail("Post should be available after update and sync")
            return
        }

        XCTAssertEqual(queryResultAfterSync, updatedPost)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let apiQuerySuccess = expectation(description: "API query is successful")
        Amplify.API.query(request: queryRequest) { result in
            switch result {
            case .success(let mutationSyncResult):
                switch mutationSyncResult {
                case .success(let data):
                    guard let post = data else {
                        XCTFail("Failed to get data")
                        return
                    }

                    XCTAssertEqual(post.model["title"] as? String, updatedPost.title)
                    XCTAssertEqual(post.model["content"] as? String, updatedPost.content)
                    XCTAssertEqual(post.model["rating"] as? Double, updatedPost.rating)
                    // version can be anything between 3 to 11 depending on how many
                    // pending mutations are overwritten in pending mutation queue
                    // while the first update mutation is being processed
                    XCTAssertTrue(post.syncMetadata.version >= 3 && post.syncMetadata.version <= 11)
                    apiQuerySuccess.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [apiQuerySuccess], timeout: networkTimeout)
    }

    private func queryPost(byId id: String) -> Post? {
        let queryExpectation = expectation(description: "Query is successful")
        var queryResult: Post?
        Amplify.DataStore.query(Post.self, byId: id) { result in
            switch result {
            case .success(let post):
                queryResult = post
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)
        return queryResult
    }
}

extension Post: Equatable {

    public static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.content == rhs.content
            && lhs.rating == rhs.rating
    }
}
