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

    func testCreateCommentAndGetCommentWithPost() throws {
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
        Amplify.DataStore.query(Comment4.self, byId: comment.id) { result in
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

    func testCreateCommentAndGetPostWithComments() throws {
        try startAmplifyAndWaitForSync()
        guard let post = savePost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = saveComment(content: "content", post: post) else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        let getCommentsCompleted = expectation(description: "get comments complete")
        Amplify.DataStore.query(Post4.self, byId: post.id) { result in
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
                queriedComments.load { result in
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

    func testDeleteAndGetComment() throws {
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
        Amplify.DataStore.query(Comment4.self, byId: comment.id) { result in
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
        let predicate = Comment4.keys.post.eq(post.id)
        Amplify.DataStore.query(Comment4.self, where: predicate) { result in
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
    func savePost(id: String = UUID().uuidString, title: String) -> Post4? {
        let post = Post4(id: id, title: title)
        var result: Post4?
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

    func saveComment(id: String = UUID().uuidString, content: String, post: Post4) -> Comment4? {
        let comment = Comment4(id: id, content: content, post: post)
        var result: Comment4?
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

extension Post4: Equatable {
    public static func == (lhs: Post4,
                           rhs: Post4) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
