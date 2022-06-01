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

    func testSavePostWithSyncAndReadPost() throws {
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let createReceived = expectation(description: "received post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost.id == post.id {
                createReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: networkTimeout)

        let queriedPostCompleted = expectation(description: "query post completed")
        Amplify.DataStore.query(Post5V2.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPost):
                XCTAssertEqual(queriedPost, post)
                queriedPostCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedPostCompleted], timeout: networkTimeout)
    }

    func testUpdatePostWithSync() throws {
        try startAmplifyAndWaitForSync()

        guard var post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let updatedTitle = "updatedTitle"
        let createReceived = expectation(description: "received post from sync event")
        let updateReceived = expectation(description: "received updated post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(syncedPost.title, updatedTitle)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                }
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: networkTimeout)

        let updatePostCompleted = expectation(description: "update post completed")
        post.title = updatedTitle
        Amplify.DataStore.save(post) { result in
            switch result {
            case .success:
                updatePostCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [updatePostCompleted, updateReceived], timeout: networkTimeout)
    }

    func testDeletePostWithSync() throws {
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let createReceived = expectation(description: "received post from sync event")
        let deleteReceived = expectation(description: "received deleted post from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }

            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: networkTimeout)

        let deletePostSuccess = expectation(description: "delete post")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .success:
                deletePostSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deletePostSuccess, deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeletePostCascadeToPostEditor() throws {
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
            XCTFail("Could not create postEditor")
            return
        }

        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 3 // 1 post, 1 user, 1 postEditor
        let deleteReceived = expectation(description: "received deleted from sync event")
        deleteReceived.expectedFulfillmentCount = 2 // 1 post, 1 postEditor
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post5V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedUser = try? mutationEvent.decodeModel() as? User5V2,
                      syncedUser.id == user.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                }
            } else if let syncedPostEditor = try? mutationEvent.decodeModel() as? PostEditor5V2,
                      syncedPostEditor.id == postEditor.id {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: networkTimeout)

        let deletePostSuccess = expectation(description: "delete post")
        Amplify.DataStore.delete(post) { result in
            switch result {
            case .success:
                deletePostSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deletePostSuccess, deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: - Helpers

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

extension Post5V2: Equatable {
    public static func == (lhs: Post5V2, rhs: Post5V2) -> Bool {
        return lhs.id == rhs.id
        && lhs.title == rhs.title
    }
}
