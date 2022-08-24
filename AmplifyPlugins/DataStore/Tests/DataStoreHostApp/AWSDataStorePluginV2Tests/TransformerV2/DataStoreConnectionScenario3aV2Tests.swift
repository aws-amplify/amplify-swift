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
(HasMany) A Post that can have many comments (Implicit)
```
 type Post3aV2 @model {
   id: ID!
   title: String!
   comments: [Comment3aV2] @hasMany
 }

 type Comment3aV2 @model {
   id: ID!
   content: String!
 }
```
See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
*/

class DataStoreConnectionScenario3aV2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post3aV2.self)
            registry.register(modelType: Comment3aV2.self)
        }

        let version: String = "1"
    }

    func testSavePostAndCommentSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post3aV2(title: "title")
        let comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
               syncedPost == post {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.decodeModel() as? Comment3aV2,
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
        
        await waitForExpectations(timeout: networkTimeout)
        
        let queriedComment = try await Amplify.DataStore.query(Comment3aV2.self, byId: comment.id)
        XCTAssertEqual(queriedComment, comment)
    }

    func testSaveCommentAndGetPostWithComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3aV2(title: "title")
        let comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        let queriedPostOptional = try await Amplify.DataStore.query(Post3aV2.self, byId: post.id)
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

        let post = Post3aV2(title: "title")
        var comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        let anotherPost = Post3aV2(title: "title")
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        _ = try await Amplify.DataStore.save(anotherPost)
        
        comment.post3aV2CommentsId = anotherPost.id
        let updatedComment = try await Amplify.DataStore.save(comment)
        XCTAssertEqual(updatedComment.post3aV2CommentsId, anotherPost.id)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post3aV2(title: "title")
        let comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        _ = try await Amplify.DataStore.delete(comment)
        
        let queriedComment = try await Amplify.DataStore.query(Comment3aV2.self, byId: comment.id)
        XCTAssertNil(queriedComment)
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3aV2(title: "title")
        let comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        let predicate = Comment3aV2.keys.post3aV2CommentsId.eq(post.id)
        let queriedComments = try await Amplify.DataStore.query(Comment3aV2.self, where: predicate)
        XCTAssertEqual(queriedComments.count, 1)
        XCTAssertEqual(queriedComments[0], comment)
    }

    func testSavePostWithSyncAndReadPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3aV2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
               syncedPost == post {
                createReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.save(post)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let queriedPost = try await Amplify.DataStore.query(Post3aV2.self, byId: post.id)
        XCTAssertEqual(queriedPost, post)
    }

    func testUpdatePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        var post = Post3aV2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let updateReceived = expectation(description: "received updated post from sync event")
        let updatedTitle = "updatedTitle"
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                         eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }
            
            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(syncedPost.title, updatedTitle)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                }
            }
        }
        
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        post.title = updatedTitle
        _ = try await Amplify.DataStore.save(post)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3aV2(title: "title")
        
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "received deleted post from sync event")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }
    

    func testDeletePostCascadeToComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post3aV2(title: "title")
        let comment = Comment3aV2(content: "content", post3aV2CommentsId: post.id)
        
        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment3aV2,
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let deleteReceived = expectation(description: "received deleted from sync event")
        deleteReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3aV2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment3aV2,
                      syncedComment.id == comment.id {
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
        // TODO: Deleting the comment should not be necessary. Cascade delete is not working
        _ = try await Amplify.DataStore.delete(comment)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }
}

extension Post3aV2: Equatable {
    public static func == (lhs: Post3aV2, rhs: Post3aV2) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
extension Comment3aV2: Equatable {
    public static func == (lhs: Comment3aV2, rhs: Comment3aV2) -> Bool {
        return lhs.id == rhs.id
            && lhs.post3aV2CommentsId == rhs.post3aV2CommentsId
            && lhs.content == rhs.content
    }
}
