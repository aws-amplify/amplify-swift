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
(HasMany) A Post that can have many comments
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

class DataStoreConnectionScenario3FlutterTests: SyncEngineFlutterIntegrationTestBase {

    func testSavePostAndCommentSyncToCloud() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let post = try TestPost3(title: "title", content: "content")
        let comment = try TestComment3(postID: post.idString(), content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }

            if let syncedPost = try? mutationEvent.modelId as? String,
               syncedPost == post.idString() {
                syncedPostReceived.fulfill()
            } else if let syncComment = try? mutationEvent.modelId as? String,
                      syncComment == comment.idString() {
                syncCommentReceived.fulfill()
            }
            
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let savePostCompleted = expectation(description: "save post completed")
        plugin.save(post.model, modelSchema: Post3.schema) { result in
            switch result {
            case .success:
                savePostCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [savePostCompleted, syncedPostReceived], timeout: networkTimeout)
        let saveCommentCompleted = expectation(description: "save comment completed")
        plugin.save(comment.model, modelSchema: Comment3.schema) { result in
            switch result {
            case .success:
                saveCommentCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [saveCommentCompleted, syncCommentReceived], timeout: networkTimeout)
        let queriedCommentCompleted = expectation(description: "query comment completed")
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment3.schema, where: Comment.keys.id.eq(comment.model.id)) { result in
            switch result {
            case .success(let queriedComment):
                let returnedComent = TestComment3(model: queriedComment[0])
                XCTAssertEqual(returnedComent, comment)
                queriedCommentCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedCommentCompleted], timeout: networkTimeout)
    }

//    func testSaveCommentAndGetPostWithComments() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        let post = try savePost(title: "title", plugin: plugin)
//        let comment = try saveComment(postID: post!.idString(), content: "content", plugin: plugin)
//
//        let getPostCompleted = expectation(description: "get post complete")
//        let getCommentsCompleted = expectation(description: "get comments complete")
//        plugin.query(FlutterSerializedModel.self, modelSchema: Post3.schema, where:  Post3.keys.id.eq(post!.model.id)) { result in
//            switch result {
//            case .success(let queriedPostOptional):
//                let queriedPost = TestPost3(model: queriedPostOptional[0])
//                XCTAssertEqual(queriedPost.idString(), post!.idString())
//                print(queriedPost.idString())
//                getPostCompleted.fulfill()
//                guard let comments = queriedPost.comments() else {
//                    XCTFail("Could not get comments")
//                    return
//                }
//                comments.load { result in
//                    switch result {
//                    case .success(let comments):
//                        XCTAssertEqual(comments.count, 1)
//                        getCommentsCompleted.fulfill()
//                    case .failure(let error):
//                        XCTFail("\(error)")
//                    }
//                }
//            case .failure(let error):
//                XCTFail("\(error)")
//            }
//        }
//
//        wait(for: [getPostCompleted, getCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
//    }

    func testUpdateComment() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = try saveComment(postID: post.idString(), content: "content", plugin: plugin) else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        try comment.setPostId(postId: anotherPost.idString())
        plugin.save(comment.model, modelSchema: Comment3.schema) { result in
            switch result {
            case .success(let updatedComment):
                let queriedComment = TestComment3(model: updatedComment)
                XCTAssertEqual(queriedComment.postId(), anotherPost.id())
                updateCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetComment() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try saveComment(postID: post.idString(), content: "content", plugin: plugin) else {
            XCTFail("Could not create comment")
            return
        }
        let deleteCommentSuccessful = expectation(description: "delete comment")
        plugin.delete(comment.model, modelSchema: Comment3.schema) { result in
            switch result {
            case .success:
                deleteCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getCommentAfterDeleteCompleted = expectation(description: "get comment after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment3.schema, where: Comment3.keys.id.eq(comment.idString())) { result in
            switch result {
            case .success(let comment):
                guard comment.isEmpty else {
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
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard try saveComment(postID: post.idString(), content: "content", plugin: plugin) != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment3.keys.postID.eq(post.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment3.schema, where: predicate) { result in
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
    
    func savePost(id: String = UUID().uuidString, title: String, plugin: AWSDataStorePlugin) throws -> TestPost3? {
        let post = try TestPost3(
            id: id,
            title: title,
            content: "content")
        var result: TestPost3?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post3.schema) { event in
            switch event {
            case .success(let project):
                result = TestPost3(model: project)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, postID: String, content: String, plugin: AWSDataStorePlugin) throws -> TestComment3? {
        let comment = try TestComment3(id: id, postID: postID, content: content)
        var result: TestComment3?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(comment.model, modelSchema: Comment3.schema) { event in
            switch event {
            case .success(let comment):
                result = TestComment3(model: comment)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

extension TestPost: Equatable {
    public static func == (lhs: TestPost, rhs: TestPost) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.title() == rhs.title()
    }
}
extension TestComment3: Equatable {
    public static func == (lhs: TestComment3, rhs: TestComment3) -> Bool {
        return lhs.idString() == rhs.idString()
            && lhs.postId() == rhs.postId()
            && lhs.content() == rhs.content()
    }
}
