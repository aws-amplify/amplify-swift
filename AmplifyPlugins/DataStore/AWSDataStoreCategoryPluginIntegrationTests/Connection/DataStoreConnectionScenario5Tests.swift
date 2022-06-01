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

class DataStoreConnectionScenario5Tests: SyncEngineIntegrationTestBase {

    func testListPostEditorByPost() throws {
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = saveUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard savePostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByPostIDCompleted = expectation(description: "list postEditor by postID complete")
        let predicateByPostId = PostEditor5.keys.post.eq(post.id)
        Amplify.DataStore.query(PostEditor5.self, where: predicateByPostId) { result in
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
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = saveUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard savePostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByEditorIdCompleted = expectation(description: "list postEditor by editorID complete")
        let predicateByUserId = PostEditor5.keys.editor.eq(user.id)
        Amplify.DataStore.query(PostEditor5.self, where: predicateByUserId) { result in
            switch result {
            case .success(let projects):
                listPostEditorByEditorIdCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByEditorIdCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetPostThenLoadPostEditors() throws {
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = saveUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard let postEditor = savePostEditor(post: post, editor: user) else {
            XCTFail("Could not create user")
            return
        }
        let getPostCompleted = expectation(description: "get post complete")
        let getPostEditorsCompleted = expectation(description: "get postEditors complete")
        Amplify.DataStore.query(Post5.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPostOptional):
                guard let queriedPost = queriedPostOptional else {
                    XCTFail("Missing queried post")
                    return
                }
                XCTAssertEqual(queriedPost.id, post.id)
                getPostCompleted.fulfill()
                guard let editors = queriedPost.editors else {
                    XCTFail("Missing editors")
                    return
                }
                editors.fetch { result in
                    switch result {
                    case .success:
                        XCTAssertEqual(editors.count, 1)
                        getPostEditorsCompleted.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted, getPostEditorsCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetUserThenLoadPostEditors() throws {
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = saveUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard let postEditor = savePostEditor(post: post, editor: user) else {
            XCTFail("Could not create user")
            return
        }
        let getUserCompleted = expectation(description: "get user complete")
        let getPostsCompleted = expectation(description: "get postEditors complete")
        Amplify.DataStore.query(User5.self, byId: user.id) { result in
            switch result {
            case .success(let queriedUserOptional):
                guard let queriedUser = queriedUserOptional else {
                    XCTFail("Missing queried user")
                    return
                }
                XCTAssertEqual(queriedUser.id, user.id)
                getUserCompleted.fulfill()
                guard let posts = queriedUser.posts else {
                    XCTFail("Missing posts")
                    return
                }
                posts.fetch { result in
                    switch result {
                    case .success:
                        XCTAssertEqual(posts.count, 1)
                        getPostsCompleted.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getUserCompleted, getPostsCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func savePost(id: String = UUID().uuidString, title: String) -> Post5? {
        let post = Post5(id: id, title: title)
        var result: Post5?
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

    func saveUser(id: String = UUID().uuidString, username: String) -> User5? {
        let user = User5(id: id, username: username)
        var result: User5?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(user) { event in
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

    func savePostEditor(id: String = UUID().uuidString, post: Post5, editor: User5) -> PostEditor5? {
        let postEditor = PostEditor5(id: id, post: post, editor: editor)
        var result: PostEditor5?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(postEditor) { event in
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
