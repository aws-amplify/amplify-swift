//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable type_body_length
class DataStoreFlutterConsecutiveUpdatesTests: SyncEngineFlutterIntegrationTestBase {
    /// - Given: API has been setup with `Post` model registered
    /// - When: A Post is saved and then immediately updated
    /// - Then: The post should be updated with new fields immediately and in the eventual consistent state
    func testSaveAndImmediatelyUpdate() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let newPost = try PostWrapper(title: "MyPost",
                          content: "This is my post.")

        let updatedPost = newPost
        try updatedPost.updateRating(rating: 5)
        try updatedPost.updateStringProp(key: "title", value: "MyUpdatedTitle")
        try updatedPost.updateStringProp(key: "content", value: "This is my updated post.")

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let updateSyncReceived = expectation(description: "Received update mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? PostWrapper(json: mutationEvent.json) as! PostWrapper, post.idString() == newPost.idString() else {
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
        plugin.save(newPost.model, modelSchema: Post.schema) { result in
            switch result {
            case .success:
                plugin.save(updatedPost.model, modelSchema: Post.schema) { result in
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
        guard let queryResult = queryPost(id: updatedPost.idString(), plugin: plugin) else {
            XCTFail("Post should be available after update")
            return
        }
        XCTAssertEqual(queryResult, updatedPost)

        wait(for: [saveSyncReceived, updateSyncReceived], timeout: networkTimeout)

        // query the updated post in eventual consistent state
        guard let queryResultAfterSync = queryPost(id: updatedPost.idString(), plugin: plugin) else {
            XCTFail("Post should be available after update and sync")
            return
        }

        XCTAssertEqual(queryResultAfterSync, updatedPost)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: "Post", byId: updatedPost.idString())
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

                    let testPost = self.convertToTestPost(model: post.model.instance as! Post)
                    XCTAssertNotNil(testPost)

                    XCTAssertEqual(testPost?.title(), updatedPost.title())
                    XCTAssertEqual(testPost?.content(), updatedPost.content())
                    XCTAssertEqual(testPost?.rating(), updatedPost.rating())
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
    func testSaveAndImmediatelyDelete() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let newPost = try PostWrapper(title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now().iso8601String,
                          rating: 3)

        let saveSyncReceived = expectation(description: "Received create mutation event on subscription for Post")
        let deleteSyncReceived = expectation(description: "Received delete mutation event on subscription for Post")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            guard let post = try? PostWrapper(json: mutationEvent.json) as! PostWrapper, post.idString() == newPost.idString() else {
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
        plugin.save(newPost.model, modelSchema: Post.schema) { result in
            switch result {
            case .success:
                sleep(3)
                plugin.delete(newPost.model, modelSchema: Post.schema, where: Post.keys.id.eq(newPost.idString())) { result in
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
        let queryResult = queryPost(id: newPost.idString(), plugin: plugin)
        XCTAssertNil(queryResult)

        wait(for: [saveSyncReceived, deleteSyncReceived], timeout: networkTimeout)

        // query the deleted post in eventual consistent state
        let queryResultAfterSync = queryPost(id: newPost.idString(), plugin: plugin)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: "Post", byId: newPost.idString())
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

                    let testPost = self.convertToTestPost(model: post.model.instance as! Post)
                    XCTAssertNotNil(testPost)
                    XCTAssertEqual(testPost?.title(), newPost.title())
                    XCTAssertEqual(testPost?.content(), newPost.content())
                    XCTAssertEqual(testPost?.rating(), newPost.rating())
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
    func testSaveThenUpdateAndImmediatelyDelete() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin

        let newPost = try PostWrapper(title: "MyPost",
                          content: "This is my post.",
                          createdAt: Temporal.DateTime.now().iso8601String,
                          rating: 3)

        var updatedPost = newPost
        try updatedPost.updateRating(rating: 5)
        try updatedPost.updateStringProp(key: "title", value: "MyUpdatedTitle")
        try updatedPost.updateStringProp(key: "content", value: "This is my updated post.")

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

            guard let post = try? PostWrapper(json: mutationEvent.json) as! PostWrapper, post.idString() == newPost.idString() else {
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
        plugin.save(newPost.model, modelSchema: Post.schema) { result in
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
        plugin.save(updatedPost.model, modelSchema: Post.schema) { result in
            sleep(2)
            switch result {
            case .success:
                plugin.delete(updatedPost.model, modelSchema: Post.schema) { result in
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
        let queryResult = queryPost(id: newPost.idString(), plugin: plugin)
        XCTAssertNil(queryResult)

        wait(for: [updateSyncReceived, deleteSyncReceived], timeout: networkTimeout)

        // query the deleted post
        let queryResultAfterSync = queryPost(id: updatedPost.idString(), plugin: plugin)
        XCTAssertNil(queryResultAfterSync)

        let queryRequest =
            GraphQLRequest<MutationSyncResult?>.query(modelName: "Post", byId: updatedPost.idString())
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
                    let testPost = self.convertToTestPost(model: post.model.instance as! Post)
                    XCTAssertNotNil(testPost)
                    XCTAssertEqual(testPost?.title(), updatedPost.title())
                    XCTAssertEqual(testPost?.content(), updatedPost.content())
                    XCTAssertEqual(testPost?.rating(), updatedPost.rating())

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

    private func queryPost(id: String, plugin: AWSDataStorePlugin) -> PostWrapper? {
        let queryExpectation = expectation(description: "Query is successful")
        var queryResult: PostWrapper?
        plugin.query(FlutterSerializedModel.self, modelSchema: Post.schema, where: Post.keys.id.eq(id)) { result in
            switch result {
            case .success(let post):
                if !post.isEmpty {
                    queryResult = PostWrapper(model: post[0])
                }
                queryExpectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
        }
        wait(for: [queryExpectation], timeout: networkTimeout)
        return queryResult
    }

    private func convertToTestPost(model: Post) -> PostWrapper? {
        var result: PostWrapper?
        do {
            result = try PostWrapper(post: model)
        } catch {
            print(error)
        }
        return result
    }
}
