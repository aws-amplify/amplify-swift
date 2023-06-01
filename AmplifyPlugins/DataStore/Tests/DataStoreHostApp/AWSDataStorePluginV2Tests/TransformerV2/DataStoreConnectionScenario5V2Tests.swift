//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

/*
 Many-to-many
 ```
 type Post5V2 @model {
   id: ID!
   title: String!
   editors: [User5V2] @manyToMany(relationName: "PostEditor5V2")
 }

 type User5V2 @model {
   id: ID!
   username: String!
   posts: [Post5V2] @manyToMany(relationName: "PostEditor5V2")
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details.
 */

class DataStoreConnectionScenario5V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post5V2.self)
            registry.register(modelType: User5V2.self)
            registry.register(modelType: PostEditor5V2.self)
        }

        let version: String = "1"
    }

    func testListPostEditorByPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post5V2(title: "title")
        let user = User5V2(username: "username")
        let postEditor = PostEditor5V2(post5V2: post, user5V2: user)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(user)
        _ = try await Amplify.DataStore.save(postEditor)
        
        let predicateByPostId = PostEditor5V2.keys.post5V2.eq(post.id)
        let queriedPostEditor = try await Amplify.DataStore.query(PostEditor5V2.self, where: predicateByPostId)
        XCTAssertNotNil(queriedPostEditor)
    }

    func testListPostEditorByUser() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post5V2(title: "title")
        let user = User5V2(username: "username")
        let postEditor = PostEditor5V2(post5V2: post, user5V2: user)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(user)
        _ = try await Amplify.DataStore.save(postEditor)
        
        let predicateByUserId = PostEditor5V2.keys.user5V2.eq(user.id)
        let queriedPostEditor = try await Amplify.DataStore.query(PostEditor5V2.self, where: predicateByUserId)
        XCTAssertNotNil(queriedPostEditor)
    }

    func testGetPostThenLoadPostEditors() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post5V2(title: "title")
        let user = User5V2(username: "username")
        let postEditor = PostEditor5V2(post5V2: post, user5V2: user)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(user)
        _ = try await Amplify.DataStore.save(postEditor)
        
        let queriedPostOptional = try await Amplify.DataStore.query(Post5V2.self, byId: post.id)
        guard let queriedPost = queriedPostOptional else {
            XCTFail("Missing queried post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)
        
        guard let editors = queriedPost.editors else {
            XCTFail("Missing editors")
            return
        }
        try await editors.fetch()
        XCTAssertEqual(editors.count, 1)
    }

    func testGetUserThenLoadPostEditors() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post5V2(title: "title")
        let user = User5V2(username: "username")
        let postEditor = PostEditor5V2(post5V2: post, user5V2: user)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(user)
        _ = try await Amplify.DataStore.save(postEditor)
        
        let queriedUserOptional = try await Amplify.DataStore.query(User5V2.self, byId: user.id)
        guard let queriedUser = queriedUserOptional else {
            XCTFail("Missing queried user")
            return
        }
        XCTAssertEqual(queriedUser.id, user.id)
        guard let posts = queriedUser.posts else {
            XCTFail("Missing posts")
            return
        }
        try await posts.fetch()
        XCTAssertEqual(posts.count, 1)
    }

    func testSavePostWithSyncAndReadPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post5V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost.id == post.id {
                createReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let queriedPost = try await Amplify.DataStore.query(Post5V2.self, byId: post.id)
        XCTAssertEqual(queriedPost, post)
    }

    func testUpdatePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        var post = Post5V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let updateReceived = expectation(description: "received updated post from sync event")
        let updatedTitle = "updatedTitle"
        post.title = updatedTitle
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(syncedPost.title, updatedTitle)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                }
            }
        }
        
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [updateReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post5V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "received deleted post from sync event")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }

            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.delete(post)
        await fulfillment(of: [deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostCascadeToPostEditor() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post5V2(title: "title")
        let user = User5V2(username: "username")
        let postEditor = PostEditor5V2(post5V2: post, user5V2: user)

        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 3 // 1 post, 1 user, 1 postEditor
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedUser = try? mutationEvent.decodeModel() as? User5V2,
                      syncedUser.id == user.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedPostEditor = try? mutationEvent.decodeModel() as? PostEditor5V2,
                      syncedPostEditor.id == postEditor.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(user)
        _ = try await Amplify.DataStore.save(postEditor)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "received deleted from sync event")
        deleteReceived.expectedFulfillmentCount = 2 // 1 post, 1 postEditor
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedPostEditor = try? mutationEvent.decodeModel() as? PostEditor5V2,
                      syncedPostEditor.id == postEditor.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.delete(post)
        await fulfillment(of: [deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }
}

extension Post5V2: Equatable {
    public static func == (lhs: Post5V2, rhs: Post5V2) -> Bool {
        return lhs.id == rhs.id
        && lhs.title == rhs.title
    }
}
