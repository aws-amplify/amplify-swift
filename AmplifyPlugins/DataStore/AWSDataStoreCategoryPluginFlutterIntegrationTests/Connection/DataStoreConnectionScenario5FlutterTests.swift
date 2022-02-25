//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
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

class DataStoreConnectionScenario5FlutterTests: SyncEngineFlutterIntegrationTestBase {

    func testListPostEditorByPost() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try saveUser(username: "username", plugin: plugin) else {
            XCTFail("Could not create user")
            return
        }
        guard try savePostEditor(post: post, editor: user, plugin: plugin) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByPostIDCompleted = expectation(description: "list postEditor by postID complete")
        let predicateByPostId = PostEditor5.keys.post.eq(post.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: PostEditor5.schema, where: predicateByPostId) { result in
            switch result {
            case .success:
                listPostEditorByPostIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testListPostEditorByUser() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try saveUser(username: "username", plugin: plugin) else {
            XCTFail("Could not create user")
            return
        }
        guard try savePostEditor(post: post, editor: user, plugin: plugin) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByEditorIdCompleted = expectation(description: "list postEditor by editorID complete")
        let predicateByUserId = PostEditor5.keys.editor.eq(user.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: PostEditor5.schema, where: predicateByUserId) { result in
            switch result {
            case .success:
                listPostEditorByEditorIdCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByEditorIdCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    /// TODO: Include testGetPostThenLoadPostEditors when nested model lazy loading is implemented
    func savePost(id: String = UUID().uuidString, title: String, plugin: AWSDataStorePlugin) throws -> Post5Wrapper? {
        let post = try Post5Wrapper(title: title)
        var result: Post5Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post5.schema) { event in
            switch event {
            case .success(let queriedPost):
                result = Post5Wrapper(model: queriedPost)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveUser(id: String = UUID().uuidString, username: String, plugin: AWSDataStorePlugin) throws -> User5Wrapper? {
        let user = try User5Wrapper(id: id, username: username)
        var result: User5Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(user.model, modelSchema: User5.schema) { event in
            switch event {
            case .success(let user):
                result = User5Wrapper(model: user)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePostEditor(id: String = UUID().uuidString, post: Post5Wrapper, editor: User5Wrapper, plugin: AWSDataStorePlugin) throws -> PostEditor5Wrapper? {
        let postEditor = try PostEditor5Wrapper(post: post.model, editor: editor.model)
        var result: PostEditor5Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(postEditor.model, modelSchema: PostEditor5.schema) { event in
            switch event {
            case .success(let queriedPostEditor):
                result = PostEditor5Wrapper(model: queriedPostEditor)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
