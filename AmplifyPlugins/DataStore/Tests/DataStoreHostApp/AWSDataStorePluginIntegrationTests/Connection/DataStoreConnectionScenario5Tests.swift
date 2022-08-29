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
 (Many-to-many) Using two one-to-many connections, an @key, and a joining @model, you can create a many-to-many
 connection.
 ```
 type Post5 @model {
   id: ID!
   title: String!
   editors: [PostEditor5] @connection(keyName: "byPost5", fields: ["id"])
 }

 # Create a join model
 type PostEditor5
   @model
   @key(name: "byPost5", fields: ["postID", "editorID"])
   @key(name: "byEditor5", fields: ["editorID", "postID"]) {
   id: ID!
   postID: ID!
   editorID: ID!
   post: Post5! @connection(fields: ["postID"])
   editor: User5! @connection(fields: ["editorID"])
 }

 type User5 @model {
   id: ID!
   username: String!
   posts: [PostEditor5] @connection(keyName: "byEditor5", fields: ["id"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details.
 */

class DataStoreConnectionScenario5Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: PostEditor5.self)
            registry.register(modelType: Post5.self)
            registry.register(modelType: User5.self)
        }

        let version: String = "1"
    }

    func testListPostEditorByPost() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let user = try await saveUser(username: "username")
        _ = try await savePostEditor(post: post, editor: user)

        let predicateByPostId = PostEditor5.keys.post.eq(post.id)
        _ = try await Amplify.DataStore.query(PostEditor5.self, where: predicateByPostId)
    }

    func testListPostEditorByUser() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let user = try await saveUser(username: "username")
        try await savePostEditor(post: post, editor: user)
        let predicateByUserId = PostEditor5.keys.editor.eq(user.id)
        _ = try await Amplify.DataStore.query(PostEditor5.self, where: predicateByUserId)
    }

    func testGetPostThenLoadPostEditors() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = try await savePost(title: "title")
        let user = try await saveUser(username: "username")
        let postEditor = try await savePostEditor(post: post, editor: user)

        let queriedPostOptional = try await Amplify.DataStore.query(Post5.self, byId: post.id)
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
        let post = try await savePost(title: "title")
        let user = try await saveUser(username: "username")
        let postEditor = try await savePostEditor(post: post, editor: user)
        
        let queriedUserOptional = try await Amplify.DataStore.query(User5.self, byId: user.id)
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

    func savePost(id: String = UUID().uuidString, title: String) async throws -> Post5 {
        let post = Post5(id: id, title: title)
        return try await Amplify.DataStore.save(post)
    }

    func saveUser(id: String = UUID().uuidString, username: String) async throws -> User5 {
        let user = User5(id: id, username: username)
        var result: User5?
        return try await Amplify.DataStore.save(user)
    }

    func savePostEditor(id: String = UUID().uuidString, post: Post5, editor: User5) async throws -> PostEditor5 {
        let postEditor = PostEditor5(id: id, post: post, editor: editor)
        return try await Amplify.DataStore.save(postEditor)
    }
}
