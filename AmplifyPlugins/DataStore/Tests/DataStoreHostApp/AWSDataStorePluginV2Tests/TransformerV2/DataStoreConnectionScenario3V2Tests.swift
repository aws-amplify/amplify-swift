//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin
#if !os(watchOS)
@testable import DataStoreHostApp
#endif

/*
(HasMany) A Post that can have many comments (Explicit)
```
 type Post3V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   comments: [Comment3V2] @hasMany(indexName: "byPost3", fields: ["id"])
 }

 type Comment3V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost3", sortKeyFields: ["content"])
   content: String!
 }
```
See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
*/

class DataStoreConnectionScenario3V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post3V2.self)
            registry.register(modelType: Comment3V2.self)
        }

        let version: String = "1"
    }

    func testSavePostAndCommentSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.decodeModel() as? Comment3V2,
                      syncComment == comment {
                syncCommentReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        await fulfillment(of: [syncedPostReceived, syncCommentReceived], timeout: TestCommonConstants.networkTimeout)
        
        let queriedComment = try await Amplify.DataStore.query(Comment3V2.self, byId: comment.id)
        XCTAssertEqual(queriedComment, comment)
    }

    func testSaveCommentAndGetPostWithComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        let queriedPostOptional = try await Amplify.DataStore.query(Post3V2.self, byId: post.id)
        guard let queriedPost = queriedPostOptional else {
            XCTFail("Could not get post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)
        guard let comments = queriedPost.comments else {
            XCTFail("Could not get comments")
            return
        }
        try await comments.fetch()
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments[0], comment)
    }

    func testUpdateComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3V2(title: "title")
        var comment = Comment3V2(postID: post.id, content: "content")
        let anotherPost = Post3V2(title: "title")
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        _ = try await Amplify.DataStore.save(anotherPost)

        comment.postID = anotherPost.id
        let updatedComment = try await Amplify.DataStore.save(comment)
        XCTAssertEqual(updatedComment.postID, anotherPost.id)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        _ = try await Amplify.DataStore.delete(comment)
        
        let queriedComment = try await Amplify.DataStore.query(Comment3V2.self, byId: comment.id)
        XCTAssertNil(queriedComment)
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        let predicate = Comment3V2.keys.postID.eq(post.id)
        let queriedComments = try await Amplify.DataStore.query(Comment3V2.self, where: predicate)
        XCTAssertEqual(queriedComments.count, 1)
        XCTAssertEqual(queriedComments[0], comment)
    }

    func testSavePostWithSyncAndReadPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                createReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let queriedPost = try await Amplify.DataStore.query(Post3V2.self, byId: post.id)
        XCTAssertEqual(queriedPost, post)
    }

    func testUpdatePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        var post = Post3V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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
        
        let updatedTitle = "updatedTitle"
        post.title = updatedTitle
        let updateReceived = expectation(description: "received updated post from sync event")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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

        let post = Post3V2(title: "title")
        
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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

    func testDeletePostCascadeToComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        
        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment3V2,
                      syncedComment.id == comment.id {
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
        _ = try await Amplify.DataStore.save(comment)
        await fulfillment(of: [createReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "received deleted from sync event")
        deleteReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment3V2,
                      syncedComment.id == comment.id {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            }
        }
        
        _ = try await Amplify.DataStore.delete(post)
        // TODO: Deleting the comment should not be necessary. Cascade delete is not working
        _ = try await Amplify.DataStore.delete(comment)
        await fulfillment(of: [deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }
}

extension Post3V2: Equatable {
    public static func == (lhs: Post3V2, rhs: Post3V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
extension Comment3V2: Equatable {
    public static func == (lhs: Comment3V2, rhs: Comment3V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.postID == rhs.postID
            && lhs.content == rhs.content
    }
}
