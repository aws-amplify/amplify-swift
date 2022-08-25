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

/* 11 Explicit Bi-Directional Belongs to Relationship
 (Belongs to) A connection that is bi-directional by adding a many-to-one connection to the type that already have a one-to-many connection.
 ```
 type Post4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   comments: [Comment4V2] @hasMany(indexName: "byPost4", fields: ["id"])
 }

 type Comment4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost4", sortKeyFields: ["content"])
   content: String!
   post: Post4V2 @belongsTo(fields: ["postID"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreConnectionScenario4V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Comment4V2.self)
            registry.register(modelType: Post4V2.self)
        }

        let version: String = "1"
    }

    func testCreateCommentAndGetCommentWithPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)

        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)

        let queriedCommentOptional = try await Amplify.DataStore.query(Comment4V2.self, byId: comment.id)
        guard let queriedComment = queriedCommentOptional else {
            XCTFail("Could not get comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)
        XCTAssertEqual(queriedComment.post, post)
    }

    func testCreateCommentAndGetPostWithComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)

        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)

        let queriedPostOptional = try await Amplify.DataStore.query(Post4V2.self, byId: post.id)
        guard let queriedPost = queriedPostOptional else {
            XCTFail("Could not get post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)
        
        guard let queriedComments = queriedPost.comments else {
            XCTFail("Could not get comments")
            return
        }
        try await queriedComments.fetch()
        XCTAssertEqual(queriedComments.count, 1)
        XCTAssertEqual(queriedComments[0], comment)
    }

    func testUpdateComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post4V2(title: "title")
        var comment = Comment4V2(content: "content", post: post)
        let anotherPost = Post4V2(title: "title")
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        _ = try await Amplify.DataStore.save(anotherPost)
        
        comment.post = anotherPost
        let updatedComment = try await Amplify.DataStore.save(comment)
        XCTAssertEqual(updatedComment.post, anotherPost)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)

        _ = try await Amplify.DataStore.delete(comment)
        let queriedComment = try await Amplify.DataStore.query(Comment4V2.self, byId: comment.id)
        XCTAssertNil(queriedComment)
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)
        
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)
        
        let predicate = Comment4V2.keys.post.eq(post.id)
        let comments = try await Amplify.DataStore.query(Comment4V2.self, where: predicate)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments[0], comment)
    }

    func testSavePostWithSyncAndReadPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post4V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost.id == post.id {
                createReceived.fulfill()
            }
        }
        
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let queriedPost = try await Amplify.DataStore.query(Post4V2.self, byId: post.id)
        XCTAssertEqual(queriedPost, post)
    }

    func testUpdatePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        var post = Post4V2(title: "title")
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost.id == post.id {
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

        let updatedTitle = "updatedTitle"
        let updateReceived = expectation(description: "received updated post from sync event")
        hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost.id == post.id {
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

        let post = Post4V2(title: "title")
        
        let createReceived = expectation(description: "received post from sync event")
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
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

        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)
        
        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        var hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment4V2,
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment4V2,
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
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    func savePost(id: String = UUID().uuidString, title: String) -> Post4V2? {
        let post = Post4V2(id: id, title: title)
        var result: Post4V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(post) { event in
            switch event {
            case .success(let project):
                result = project
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, content: String, post: Post4V2) -> Comment4V2? {
        let comment = Comment4V2(id: id, content: content, post: post)
        var result: Comment4V2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(comment) { event in
            switch event {
            case .success(let project):
                result = project
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

extension Post4V2: Equatable {
    public static func == (lhs: Post4V2,
                           rhs: Post4V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}

extension Comment4V2: Equatable {
    public static func == (lhs: Comment4V2, rhs: Comment4V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.post == rhs.post
            && lhs.content == rhs.content
    }
}
