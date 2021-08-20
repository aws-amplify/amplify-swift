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
class DataStoreEndToEndTests: SyncEngineFlutterIntegrationTestBase {

    func testCreateMutateDelete() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()

        let title = "This is a new post I created"
        let date = Temporal.DateTime.now().iso8601String
        
        let newPost = try TestPost(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        let updatedPost = try TestPost(
            id: newPost.idString(),
            title: title,
            content: "UPDATED CONTENT from DataStoreEndToEndTests at \(date)",
            createdAt: date
        )

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
            
//            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
//                return
//            }
                guard let post = try? TestPost(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content(), newPost.content())
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content(), updatedPost.content())
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

        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        plugin.save(updatedPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)

        plugin.delete(updatedPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [deleteReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - attempt to update the existing post with a condition that matches existing data
    /// - Then:
    ///    - the update with condition that matches existing data will be applied and returned.
    func testCreateThenMutateWithCondition() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()
        
        let title = "This is a new post I created"
        let date = Temporal.DateTime.now().iso8601String
        
        let post = Post.keys

        let newPost = try TestPost(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        let updatedPost = try TestPost(
            id: newPost.idString(),
            title: title,
            content: "UPDATED CONTENT from DataStoreEndToEndTests at \(date)",
            createdAt: date
        )

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
                guard let post = try? TestPost(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content(), newPost.content())
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content(), updatedPost.content())
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        plugin.save(updatedPost.model, modelSchema: Post.schema, where: post.title == title) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - update the post's content directly using `storageAdapter` to persist the update in local store
    ///    - save the post with the condition that matches the updated content, bypassing local store validation
    /// - Then:
    ///    - the post is first only updated on local store is not sync to the remote
    ///    - the save with condition reaches the remote and fails with conditional save failed
//    func testCreateThenMutateWithConditionFailOnSync() throws {
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        try startAmplifyAndWaitForSync()
//
//        let title = "This is a new post I created"
//        let date = Temporal.DateTime.now().iso8601String
//        
//        let post = Post.keys
//
//        let newPost = try TestPost(
//            title: title,
//            content: "Original content from DataStoreEndToEndTests at \(date)",
//            createdAt: date)
//
//        let updatedContent = "UPDATED CONTENT from DataStoreEndToEndTests at \(date)"
//        let updatedPost = try TestPost(
//            id: newPost.idString(),
//            title: title,
//            content: updatedContent,
//            createdAt: date
//        )
//
//        let createReceived = expectation(description: "Create notification received")
//        let updateLocalSuccess = expectation(description: "Update local successful")
//        let conditionalReceived = expectation(description: "Conditional save failed received")
//
//        let syncReceivedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncReceived)
//        let conditionalSaveFailedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.conditionalSaveFailed)
//        let filters = HubFilters.any(filters: syncReceivedFilter, conditionalSaveFailedFilter)
//        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filters) { payload in
//            guard let mutationEvent = payload.data as? MutationEvent
//                else {
//                    XCTFail("Can't cast payload as mutation event")
//                    return
//            }
//
//            // This check is to protect against stray events being processed after the test has completed,
//            // and it shouldn't be construed as a pattern necessary for production applications.
//            guard let post = try? TestPost(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
//                return
//            }
//
//            if payload.eventName == HubPayload.EventName.DataStore.syncReceived {
//                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
//                    XCTAssertEqual(post.content(), newPost.content())
//                    XCTAssertEqual(mutationEvent.version, 1)
//                    createReceived.fulfill()
//                    return
//                }
//            } else if payload.eventName == HubPayload.EventName.DataStore.conditionalSaveFailed {
//                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
//                    XCTAssertEqual(post.title(), updatedPost.title())
//                    XCTAssertEqual(mutationEvent.version, 1)
//                    conditionalReceived.fulfill()
//                    return
//                }
//            }
//        }
//
//        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
//            XCTFail("Listener not registered for hub")
//            return
//        }
//
//        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }
//
//        wait(for: [createReceived], timeout: networkTimeout)
//
//        storageAdapter.save(updatedPost.model) { result in
//            switch result {
//            case .success(let post):
//                print("Saved post \(post)")
//                updateLocalSuccess.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to save post directly to local store \(error)")
//            }
//        }
//
//        wait(for: [updateLocalSuccess], timeout: networkTimeout)
//
//        plugin.save(updatedPost.model, modelSchema: Post.schema, where: post.content == updatedContent) { _ in }
//
//        wait(for: [conditionalReceived], timeout: networkTimeout)
//    }
}
