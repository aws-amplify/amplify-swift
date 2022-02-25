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
        let post = try Post3Wrapper(title: "title")
        let comment = try Comment3Wrapper(postID: post.idString(), content: "content")
        let syncedPostReceived = expectation(description: "received post from sync event")
        let syncCommentReceived = expectation(description: "received comment from sync event")
        let hubListener = Amplify.Hub.listen(to: .dataStore,
                                             eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Could not cast payload to mutation event")
                return
            }
            if let syncedPost = mutationEvent.modelId as String?,
               syncedPost == post.idString() {
                syncedPostReceived.fulfill()
            } else if let syncComment = mutationEvent.modelId as String?,
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
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment3.schema, where: Comment3.keys.id.eq(comment.model.id)) { result in
            switch result {
            case .success(let queriedComment):
                let returnedComent = Comment3Wrapper(model: queriedComment[0])
                XCTAssertEqual(returnedComent, comment)
                queriedCommentCompleted.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [queriedCommentCompleted], timeout: networkTimeout)
    }

    /// TODO:  Include testSaveCommentAndGetPostWithComments test when nested model lazy loading is implemented
    func testUpdateComment() throws {
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
        guard let anotherPost = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        try comment.setPostId(postId: anotherPost.idString())
        plugin.save(comment.model, modelSchema: Comment3.schema) { result in
            switch result {
            case .success(let updatedComment):
                let queriedComment = Comment3Wrapper(model: updatedComment)
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
    
    func savePost(id: String = UUID().uuidString, title: String, plugin: AWSDataStorePlugin) throws -> Post3Wrapper? {
        let post = try Post3Wrapper(
            id: id,
            title: title)
        var result: Post3Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post3.schema) { event in
            switch event {
            case .success(let project):
                result = Post3Wrapper(model: project)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, postID: String, content: String, plugin: AWSDataStorePlugin) throws -> Comment3Wrapper? {
        let comment = try Comment3Wrapper(id: id, postID: postID, content: content)
        var result: Comment3Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(comment.model, modelSchema: Comment3.schema) { event in
            switch event {
            case .success(let comment):
                result = Comment3Wrapper(model: comment)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
