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
(HasMany) A Post that can have many comments (Explicit)
```
 type Post3V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   comments: [Comment3V2] @hasMany(indexName: "byPost3", fields: ["id"])
 }

 type Comment3V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost3", sortKeyFields: ["content"])
   content: String!
 }
```
See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
*/

class DataStoreConnectionScenario3V2Tests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post3V2.self)
            registry.register(modelType: Comment3V2.self)
        }

        let version: String = "1"
    }

    func testSavePostAndCommentSyncToCloud() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        let post = Post3V2(title: "title")
        let comment = Comment3V2(postID: post.id, content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.decodeModel() as? Comment3V2,
                      syncComment == comment {
                syncCommentReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let savePostCompleted = expectation(description: "save post completed")
        Amplify.DataStore.save(post) { result in
            switch result {
            case .success:
                savePostCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [savePostCompleted, syncedPostReceived], timeout: networkTimeout)
        let saveCommentCompleted = expectation(description: "save comment completed")
        Amplify.DataStore.save(comment) { result in
            switch result {
            case .success:
                saveCommentCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveCommentCompleted, syncCommentReceived], timeout: networkTimeout)
        let queriedCommentCompleted = expectation(description: "query comment completed")
        Amplify.DataStore.query(Comment3V2.self, byId: comment.id) { result in
            switch result {
            case .success(let queriedComment):
                XCTAssertEqual(queriedComment, comment)
                queriedCommentCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedCommentCompleted], timeout: networkTimeout)
    }

    func testSaveCommentAndGetPostWithComments() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard saveComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        let getCommentsCompleted = expectation(description: "get comments complete")
        Amplify.DataStore.query(Post3V2.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPostOptional):
                guard let queriedPost = queriedPostOptional else {
                    XCTFail("Could not get post")
                    return
                }
                XCTAssertEqual(queriedPost.id, post.id)
                getPostCompleted.fulfill()
                guard let comments = queriedPost.comments else {
                    XCTFail("Could not get comments")
                    return
                }
                comments.load { result in
                    switch result {
                    case .success(let comments):
                        XCTAssertEqual(comments.count, 1)
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

    func testUpdateComment() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = saveComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        comment.postID = anotherPost.id
        Amplify.DataStore.save(comment) { result in
            switch result {
            case .success(let updatedComment):
                XCTAssertEqual(updatedComment.postID, anotherPost.id)
                updateCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetComment() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(postID: post.id, content: "content") else {
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
        Amplify.DataStore.query(Comment3V2.self, byId: comment.id) { result in
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

    func testListCommentsByPostID() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard saveComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment3V2.keys.postID.eq(post.id)
        Amplify.DataStore.query(Comment3V2.self, where: predicate) { result in
            switch result {
            case .success(let projects):
                XCTAssertEqual(projects.count, 1)
                listCommentByPostIDCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testSavePostWithSyncAndReadPost() throws {
        setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                createReceived.fulfill()
            }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        wait(for: [createReceived], timeout: networkTimeout)

        let queriedPostCompleted = expectation(description: "query post completed")
        Amplify.DataStore.query(Post3V2.self, byId: post.id) { result in
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
        setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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
        setUp(withModels: TestModelRegistration())
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
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

    func testDeletePostCascadeToComments() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(postID: post.id, content: "content") else {
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

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3V2,
               syncedPost == post {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }
            } else if let syncedComment = try? mutationEvent.decodeModel() as? Comment3V2,
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
        wait(for: [deletePostSuccess], timeout: TestCommonConstants.networkTimeout)

        // TODO: Deleting the comment should not be necessary. Cascade delete is not working
        let deleteCommentSuccess = expectation(description: "delete comment")
        Amplify.DataStore.delete(comment) { result in
            switch result {
            case .success:
                deleteCommentSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccess, deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func savePost(id: String = UUID().uuidString, title: String) -> Post3V2? {
        let post = Post3V2(id: id, title: title)
        var result: Post3V2?
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

    func saveComment(id: String = UUID().uuidString, postID: String, content: String) -> Comment3V2? {
        let comment = Comment3V2(id: id, postID: postID, content: content)
        var result: Comment3V2?
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

extension Post3V2: Equatable {
    public static func == (lhs: Post3V2, rhs: Post3V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
extension Comment3V2: Equatable {
    public static func == (lhs: Comment3V2, rhs: Comment3V2) -> Bool {
        return lhs.id == rhs.id
            && lhs.postID == rhs.postID
            && lhs.content == rhs.content
    }
}
