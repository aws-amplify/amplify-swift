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
@testable import DataStoreHostApp

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

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // Post is saved and then immediately updated
        _ = try await Amplify.DataStore.save(newPost)
        _ = try await Amplify.DataStore.save(updatedPost)

        // query the updated post immediately
        let queryResult = try await queryPost(byId: updatedPost.id)
        XCTAssertEqual(queryResult, updatedPost)

        await waitForExpectations(timeout: networkTimeout)

        // query the updated post in eventual consistent state
        let queryResultAfterSync = try await queryPost(byId: updatedPost.id)
        XCTAssertEqual(queryResultAfterSync, updatedPost)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let mutationSyncResult = try await Amplify.API.query(request: queryRequest)
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
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
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

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // Post is saved and then immediately deleted
        _ = try await Amplify.DataStore.save(newPost)
        try await Amplify.DataStore.delete(newPost)

        // query the deleted post immediately
        let queryResult = try await queryPost(byId: newPost.id)
        XCTAssertNil(queryResult)

        await waitForExpectations(timeout: networkTimeout)

        // query the deleted post in eventual consistent state
        let queryResultAfterSync = try await queryPost(byId: newPost.id)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: newPost.modelName, byId: newPost.id)
        let mutationSyncResult = try await Amplify.API.query(request: queryRequest)
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
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
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

        let saveSyncReceived = asyncExpectation(description: "Received create mutation event on subscription for Post")
        let updateSyncReceived = asyncExpectation(description: "Received update mutation event on subscription for Post")
        let deleteSyncReceived = asyncExpectation(description: "Received delete mutation event on subscription for Post")

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
                Task { await saveSyncReceived.fulfill() }
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                XCTAssertEqual(post, updatedPost)
                XCTAssertEqual(mutationEvent.version, 2)
                Task { await updateSyncReceived.fulfill() }
                return
            }

            if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                XCTAssertEqual(post, updatedPost)
                XCTAssertEqual(mutationEvent.version, 3)
                Task { await deleteSyncReceived.fulfill() }
                return
            }
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        // save the post, update and delete immediately
        _ = try await Amplify.DataStore.save(newPost)
        await waitForExpectations([saveSyncReceived], timeout: networkTimeout)

        _ = try await Amplify.DataStore.save(updatedPost)
        try await Amplify.DataStore.delete(updatedPost)

        // query the deleted post immediately
        let queryResult = try await queryPost(byId: newPost.id)
        XCTAssertNil(queryResult)

        await waitForExpectations([updateSyncReceived, deleteSyncReceived], timeout: networkTimeout)

        // query the deleted post
        let queryResultAfterSync = try await queryPost(byId: updatedPost.id)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest = GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let mutationSyncResult = try await Amplify.API.query(request: queryRequest)
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
                case .failure(let error):
                    XCTFail("Error: \(error)")
                }
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

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(newPost)
        wait(for: [saveSyncReceived], timeout: networkTimeout)

        for index in 1 ... updateCount {
            updatedPost.title = updatedPostDefaultTitle + String(index)
            _ = try await Amplify.DataStore.save(updatedPost)
        }

        wait(for: [updateSyncReceived], timeout: networkTimeout)

        // query the updated post in eventual consistent state
        let queryResultAfterSync = try await queryPost(byId: updatedPost.id)
        XCTAssertEqual(queryResultAfterSync, updatedPost)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: updatedPost.modelName, byId: updatedPost.id)
        let apiQuerySuccess = expectation(description: "API query is successful")
        let mutationSyncResult = try await Amplify.API.query(request: queryRequest)
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
        case .failure(let error):
            XCTFail("Error: \(error)")
        }
    }
    
    func queryPost(byId id: String) async throws -> Post? {
        return try await Amplify.DataStore.query(Post.self, byId: id)
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
