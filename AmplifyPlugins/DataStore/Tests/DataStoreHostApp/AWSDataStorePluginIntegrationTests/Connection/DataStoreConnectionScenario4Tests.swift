//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

/*
 (Belongs to) A connection that is bi-directional by adding a many-to-one connection to the type that already have a one-to-many connection.
 ```
 type Post4 @model {
   id: ID!
   title: String!
   comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
 }

 type Comment4 @model
   @key(name: "byPost4", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
   post: Post4 @connection(fields: ["postID"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */

class DataStoreConnectionScenario4Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Comment4.self)
            registry.register(modelType: Post4.self)
        }

        let version: String = "1"
    }

    func testCreateCommentAndGetCommentWithPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let comment = try await saveComment(content: "content", post: post)
        let queriedCommentOptional = try await Amplify.DataStore.query(Comment4.self, byId: comment.id)
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
        let post = try await savePost(title: "title")
        _ = try await saveComment(content: "content", post: post)
        let queriedPostOptional = try await Amplify.DataStore.query(Post4.self, byId: post.id)
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
    }

    func testUpdateComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        var comment = try await saveComment(content: "content", post: post)
        let anotherPost = try await savePost(title: "title")
        comment.post = anotherPost
        let updatedComment = try await Amplify.DataStore.save(comment)
        XCTAssertEqual(updatedComment.post, anotherPost)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let comment = try await saveComment(content: "content", post: post)
        try await Amplify.DataStore.delete(comment)
        let queriedComment = try await Amplify.DataStore.query(Comment4.self, byId: comment.id)
        guard queriedComment == nil else {
            XCTFail("Should be nil after deletion")
            return
        }
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        _ = try await saveComment(content: "content", post: post)
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment4.keys.post.eq(post.id)
        let queriedComments = try await Amplify.DataStore.query(Comment4.self, where: predicate)
        XCTAssertEqual(queriedComments.count, 1)
    }
    
    func savePost(id: String = UUID().uuidString, title: String) async throws -> Post4 {
        let post = Post4(id: id, title: title)
        return try await Amplify.DataStore.save(post)
    }

    func saveComment(id: String = UUID().uuidString, content: String, post: Post4) async throws -> Comment4 {
        let comment = Comment4(id: id, content: content, post: post)
        return try await Amplify.DataStore.save(comment)
    }
}

extension Post4: Equatable {
    public static func == (lhs: Post4,
                           rhs: Post4) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
