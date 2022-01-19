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
type Post3 @model {
  id: ID!
  title: String!
  comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
}

type Comment3 @model
  @key(name: "byPost3", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
}
```
See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
*/

class DataStoreConnectionScenario3Tests: SyncEngineIntegrationTestBase {

    func testSavePostAndCommentSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let post = Post3(title: "title")
        let comment = Comment3(postID: post.id, content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.decodeModel() as? Post3,
               syncedPost == post {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.decodeModel() as? Comment3,
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
        Amplify.DataStore.query(Comment3.self, byId: comment.id) { result in
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
        Amplify.DataStore.query(Post3.self, byId: post.id) { result in
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
        Amplify.DataStore.query(Comment3.self, byId: comment.id) { result in
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
        guard saveComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment3.keys.postID.eq(post.id)
        Amplify.DataStore.query(Comment3.self, where: predicate) { result in
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

    func savePost(id: String = UUID().uuidString, title: String) -> Post3? {
        let post = Post3(id: id, title: title)
        var result: Post3?
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

    func saveComment(id: String = UUID().uuidString, postID: String, content: String) -> Comment3? {
        let comment = Comment3(id: id, postID: postID, content: content)
        var result: Comment3?
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

extension Post3: Equatable {
    public static func == (lhs: Post3, rhs: Post3) -> Bool {
        return lhs.id == rhs.id
            && lhs.title == rhs.title
    }
}
extension Comment3: Equatable {
    public static func == (lhs: Comment3, rhs: Comment3) -> Bool {
        return lhs.id == rhs.id
            && lhs.postID == rhs.postID
            && lhs.content == rhs.content
    }
}
