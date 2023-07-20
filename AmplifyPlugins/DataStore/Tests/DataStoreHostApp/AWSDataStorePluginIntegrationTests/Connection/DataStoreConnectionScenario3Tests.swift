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
type Post3 @model {
  id: ID!
  title: String!
  comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
}

type Comment3 @model
  @key(name: "byPost3", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
}
```
See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
*/

class DataStoreConnectionScenario3Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post3.self)
            registry.register(modelType: Comment3.self)
        }

        let version: String = "1"
    }

    func testSavePostAndCommentSyncToCloud() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post3(title: "title")
        let comment = Comment3(postID: post.id, content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3,
               syncedPost == post {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.decodeModel() as? Comment3,
                      syncComment == comment {
                syncCommentReceived.fulfill()
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [syncedPostReceived], timeout: networkTimeout)
        _ = try await Amplify.DataStore.save(comment)
        await fulfillment(of: [syncCommentReceived], timeout: networkTimeout)
        
        let queriedComment = try await Amplify.DataStore.query(Comment3.self, byId: comment.id)
        XCTAssertEqual(queriedComment, comment)
    }

    func testSaveCommentAndGetPostWithComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = try await savePost(title: "title")
        _ = try await saveComment(postID: post.id, content: "content")

        let queriedPostOptional = try await Amplify.DataStore.query(Post3.self, byId: post.id)
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
    }

    func testUpdateComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = try await savePost(title: "title")
        var comment = try await saveComment(postID: post.id, content: "content")
        let anotherPost = try await savePost(title: "title")

        comment.postID = anotherPost.id
        let updatedComment = try await Amplify.DataStore.save(comment)
        XCTAssertEqual(updatedComment.postID, anotherPost.id)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let comment = try await saveComment(postID: post.id, content: "content")
        try await Amplify.DataStore.delete(comment)
        let queriedComment = try await Amplify.DataStore.query(Comment3.self, byId: comment.id)
        guard queriedComment == nil else {
            XCTFail("Should be nil after deletion")
            return
        }
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        _ = try await saveComment(postID: post.id, content: "content")
        let predicate = Comment3.keys.postID.eq(post.id)
        let comments = try await Amplify.DataStore.query(Comment3.self, where: predicate)
        XCTAssertEqual(comments.count, 1)
    }

    func savePost(id: String = UUID().uuidString, title: String) async throws -> Post3 {
        let post = Post3(id: id, title: title)
        return try await Amplify.DataStore.save(post)
    }

    func saveComment(id: String = UUID().uuidString, postID: String, content: String) async throws -> Comment3 {
        let comment = Comment3(id: id, postID: postID, content: content)
        return try await Amplify.DataStore.save(comment)
    }
}

extension Post3: Equatable {
    public static func == (lhs: Post3, rhs: Post3) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
extension Comment3: Equatable {
    public static func == (lhs: Comment3, rhs: Comment3) -> Bool {
        return lhs.id == rhs.id
            && lhs.postID == rhs.postID
            && lhs.content == rhs.content
    }
}
