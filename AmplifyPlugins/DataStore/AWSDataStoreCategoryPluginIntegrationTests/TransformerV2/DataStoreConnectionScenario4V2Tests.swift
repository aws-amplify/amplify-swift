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
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        Amplify.DataStore.query(Comment4V2.self, byId: comment.id) { result in
            switch result {
            case .success(let queriedCommentOptional):
                guard let queriedComment = queriedCommentOptional else {
                    XCTFail("Could not get comment")
                    return
                }
                XCTAssertEqual(queriedComment.id, comment.id)
                XCTAssertEqual(queriedComment.post, post)
                getCommentCompleted.fulfill()

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreateCommentAndGetPostWithComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard saveComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        let getCommentsCompleted = expectation(description: "get comments complete")
        Amplify.DataStore.query(Post4V2.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPostOptional):
                guard let queriedPost = queriedPostOptional else {
                    XCTFail("Could not get post")
                    return
                }
                XCTAssertEqual(queriedPost.id, post.id)
                getPostCompleted.fulfill()
                guard let queriedComments = queriedPost.comments else {
                    XCTFail("Could not get comments")
                    return
                }
                queriedComments.fetch { result in
                    switch result {
                    case .success:
                        XCTAssertEqual(queriedComments.count, 1)
                        getCommentsCompleted.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted, getCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdateComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = saveComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        comment.post = anotherPost
        Amplify.DataStore.save(comment) { result in
            switch result {
            case .success(let updatedComment):
                XCTAssertEqual(updatedComment.post, anotherPost)
                updateCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let deleteCommentSuccessful = expectation(description: "delete comment")
        Amplify.DataStore.delete(comment) { result in
            switch result {
            case .success:
                deleteCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getCommentAfterDeleteCompleted = expectation(description: "get comment after deleted complete")
        Amplify.DataStore.query(Comment4V2.self, byId: comment.id) { result in
            switch result {
            case .success(let comment):
                guard comment == nil else {
                    XCTFail("Should be nil after deletion")
                    return
                }
                getCommentAfterDeleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testListCommentsByPostID() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard saveComment(content: "content", post: post) != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment4V2.keys.post.eq(post.id)
        Amplify.DataStore.query(Comment4V2.self, where: predicate) { result in
            switch result {
            case .success(let comments):
                XCTAssertEqual(comments.count, 1)
                listCommentByPostIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testSavePostWithSyncAndReadPost() async throws {
        await setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
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
        Amplify.DataStore.query(Post4V2.self, byId: post.id) { result in
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

    func testUpdatePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
               syncedPost.id == post.id {
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

    func testDeletePostWithSync() async throws {
        await setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post4V2,
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

    func testDeletePostCascadeToComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }
        let createReceived = expectation(description: "received created from sync event")
        createReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        let deleteReceived = expectation(description: "received deleted from sync event")
        deleteReceived.expectedFulfillmentCount = 2 // 1 post and 1 comment
        let hubListener = Amplify.Hub.listen(to: .dataStore,
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
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment4V2,
                      syncedComment.id == comment.id {
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
