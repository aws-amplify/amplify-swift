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
        guard savePostEditor(post5V2: post, user5V2: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByPostIDCompleted = expectation(description: "list postEditor by postID complete")
        let predicateByPostId = PostEditor5V2.keys.post5V2.eq(post.id)
        Amplify.DataStore.query(PostEditor5V2.self, where: predicateByPostId) { result in
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
        guard savePostEditor(post5V2: post, user5V2: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByEditorIdCompleted = expectation(description: "list postEditor by editorID complete")
        let predicateByUserId = PostEditor5V2.keys.user5V2.eq(user.id)
        Amplify.DataStore.query(PostEditor5V2.self, where: predicateByUserId) { result in
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
        guard let postEditor = savePostEditor(post5V2: post, user5V2: user) else {
            XCTFail("Could not create user")
            return
        }
        let getPostCompleted = expectation(description: "get post complete")
        let getPostEditorsCompleted = expectation(description: "get postEditors complete")
        Amplify.DataStore.query(Post5V2.self, byId: post.id) { result in
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
                editors.load { result in
                    switch result {
                    case .success(let postEditors):
                        XCTAssertEqual(postEditors.count, 1)
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
        guard let postEditor = savePostEditor(post5V2: post, user5V2: user) else {
            XCTFail("Could not create user")
            return
        }
        let getUserCompleted = expectation(description: "get user complete")
        let getPostsCompleted = expectation(description: "get postEditors complete")
        Amplify.DataStore.query(User5V2.self, byId: user.id) { result in
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
                posts.load { result in
                    switch result {
                    case .success(let posts):
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

    func savePost(id: String = UUID().uuidString, title: String) -> Post5V2? {
        let post = Post5V2(id: id, title: title)
        var result: Post5V2?
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

    func saveUser(id: String = UUID().uuidString, username: String) -> User5V2? {
        let user = User5V2(id: id, username: username)
        var result: User5V2?
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

    func savePostEditor(id: String = UUID().uuidString, post5V2: Post5V2, user5V2: User5V2) -> PostEditor5V2? {
        let postEditor = PostEditor5V2(id: id, post5V2: post5V2, user5V2: user5V2)
        var result: PostEditor5V2?
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
