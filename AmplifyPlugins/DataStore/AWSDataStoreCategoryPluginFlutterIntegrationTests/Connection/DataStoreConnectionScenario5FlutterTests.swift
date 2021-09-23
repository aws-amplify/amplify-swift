//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

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
            case .success(let projects):
                listPostEditorByEditorIdCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByEditorIdCompleted], timeout: TestCommonConstants.networkTimeout)
    }

//    func testGetPostThenLoadPostEditors() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        guard let post = try savePost(title: "title", plugin: plugin) else {
//            XCTFail("Could not create post")
//            return
//        }
//        guard let user = try saveUser(username: "username", plugin: plugin) else {
//            XCTFail("Could not create user")
//            return
//        }
//        guard let postEditor = try savePostEditor(post: post, editor: user, plugin: plugin) else {
//            XCTFail("Could not create user")
//            return
//        }
//        let getPostCompleted = expectation(description: "get post complete")
//        let getPostEditorsCompleted = expectation(description: "get postEditors complete")
//        plugin.query(FlutterSerializedModel.self, modelSchema: Post5.schema, where: Post5.keys.id.eq(post.idString())) { result in
//            switch result {
//            case .success(let queriedPostOptional):
//                let queriedPost = TestPost5(model: queriedPostOptional[0])
//                XCTAssertEqual(queriedPost.idString(), post.idString())
//                getPostCompleted.fulfill()
//                guard let editors = queriedPost.editors() else {
//                    XCTFail("Missing editors")
//                    return
//                }
//                editors.load { result in
//                    switch result {
//                    case .success(let postEditors):
//                        XCTAssertEqual(postEditors.count, 1)
//                        getPostEditorsCompleted.fulfill()
//                    case .failure(let error):
//                        XCTFail("\(error)")
//                    }
//                }
//            case .failure(let error):
//                XCTFail("\(error)")
//            }
//        }
//        wait(for: [getPostCompleted, getPostEditorsCompleted], timeout: TestCommonConstants.networkTimeout)
//    }

//    func testGetUserThenLoadPostEditors() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        guard let post = try savePost(title: "title", plugin: plugin) else {
//            XCTFail("Could not create post")
//            return
//        }
//        guard let user = try saveUser(username: "username", plugin: plugin) else {
//            XCTFail("Could not create user")
//            return
//        }
//        guard let postEditor = try savePostEditor(post: post, editor: user, plugin: plugin) else {
//            XCTFail("Could not create user")
//            return
//        }
//        let getUserCompleted = expectation(description: "get user complete")
//        let getPostsCompleted = expectation(description: "get postEditors complete")
//        plugin.query(FlutterSerializedModel.self, modelSchema: User5.schema, where: Post5.keys.id.eq(user.idString())) { result in
//            switch result {
//            case .success(let queriedUserOptional):
//                guard let queriedUser = queriedUserOptional else {
//                    XCTFail("Missing queried user")
//                    return
//                }
//                XCTAssertEqual(queriedUser.id, user.id())
//                getUserCompleted.fulfill()
//                guard let posts = queriedUser.posts else {
//                    XCTFail("Missing posts")
//                    return
//                }
//                posts.load { result in
//                    switch result {
//                    case .success(let posts):
//                        XCTAssertEqual(posts.count, 1)
//                        getPostsCompleted.fulfill()
//                    case .failure(let error):
//                        XCTFail("\(error)")
//                    }
//                }
//            case .failure(let error):
//                XCTFail("\(error)")
//            }
//        }
//        wait(for: [getUserCompleted, getPostsCompleted], timeout: TestCommonConstants.networkTimeout)
//    }

    func savePost(id: String = UUID().uuidString, title: String, plugin: AWSDataStorePlugin) throws -> TestPost5? {
        let post = try TestPost5(title: title)
        var result: TestPost5?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post5.schema) { event in
            switch event {
            case .success(let queriedPost):
                result = TestPost5(model: queriedPost)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveUser(id: String = UUID().uuidString, username: String, plugin: AWSDataStorePlugin) throws -> TestUser5? {
        let user = try TestUser5(id: id, username: username)
        var result: TestUser5?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(user.model, modelSchema: User5.schema) { event in
            switch event {
            case .success(let user):
                result = TestUser5(model: user)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePostEditor(id: String = UUID().uuidString, post: TestPost5, editor: TestUser5, plugin: AWSDataStorePlugin) throws -> TestPostEditor5? {
        let postEditor = try TestPostEditor5(post: post.model, editor: editor.model)
        var result: TestPostEditor5?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(postEditor.model, modelSchema: PostEditor5.schema) { event in
            switch event {
            case .success(let queriedPostEditor):
                result = TestPostEditor5(model: queriedPostEditor)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
