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

class DataStoreConnectionScenario4FlutterTests: SyncEngineFlutterIntegrationTestBase {

    func testCreateCommentAndGetCommentWithPost() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let post = try savePost(title: "title", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = try saveComment(content: "content", post: post, plugin: plugin) else {
            XCTFail("Could not create comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment4.schema, where: Comment4.keys.id.eq(comment.idString())) { result in
            switch result {
            case .success(let queriedCommentOptional):
                let queriedComment = TestComment4(model: queriedCommentOptional[0])
                XCTAssertEqual(queriedComment.idString(), comment.idString())
                XCTAssertEqual(queriedComment.post()!["id"], post.id())
                getCommentCompleted.fulfill()

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)
    }

//    func testCreateCommentAndGetPostWithComments() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//
//        guard let post = try savePost(title: "title", plugin: plugin) else {
//            XCTFail("Could not create post")
//            return
//        }
//        guard let comment = try saveComment(content: "content", post: post, plugin: plugin) else {
//            XCTFail("Could not create comment")
//            return
//        }
//
//        let getPostCompleted = expectation(description: "get post complete")
//        let getCommentsCompleted = expectation(description: "get comments complete")
//        plugin.query(FlutterSerializedModel.self, modelSchema: Post4.schema, where: Post4.keys.id.eq(post.idString())) { result in
//            switch result {
//            case .success(let queriedPostOptional):
//                let queriedPost = TestPost3(model: queriedPostOptional[0])
//
//                XCTAssertEqual(queriedPost.id(), post.id())
//                getPostCompleted.fulfill()
//                guard let queriedComments = queriedPost.comments else {
//                    XCTFail("Could not get comments")
//                    return
//                }
//                queriedComments.load { result in
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
//        wait(for: [getPostCompleted, getCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
//    }

    func testUpdateComment() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin

        guard let post =  try savePost(title: "post", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        
        guard let comment =  try saveComment(content: "content", post: post, plugin: plugin) else {
            XCTFail("Could not create comment")
            return
        }
        
        guard let anotherPost =  try savePost(title: "anotherPost", plugin: plugin) else {
            XCTFail("Could not create post")
            return
        }
        
        let updateCommentSuccessful = expectation(description: "update comment")
        try comment.setPost(post: anotherPost.model)
        plugin.save(comment.model, modelSchema: Comment4.schema ) { result in
            switch result {
            case .success(let updatedComment):
                let queriedComment = TestComment4(model: updatedComment)
                XCTAssertEqual(queriedComment.post()!["id"], anotherPost.id())
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
        guard let comment = try saveComment(content: "content", post: post, plugin: plugin) else {
            XCTFail("Could not create comment")
            return
        }

        let deleteCommentSuccessful = expectation(description: "delete comment")
        plugin.delete(comment.model, modelSchema: Comment4.schema) { result in
            switch result {
            case .success:
                deleteCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getCommentAfterDeleteCompleted = expectation(description: "get comment after deleted complete")
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment4.schema, where: Comment4.keys.id.eq(comment.idString())) { result in
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
        guard try saveComment(content: "content", post: post, plugin: plugin) != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment4.keys.post.eq(post.idString())
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment4.schema, where: predicate) { result in
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
    
    func savePost(id: String = UUID().uuidString, title: String, plugin: AWSDataStorePlugin) throws -> TestPost3? {
        let post = try TestPost3(id: id, title: title, content: "content")
        var result: TestPost3?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post4.schema) { event in
            switch event {
            case .success(let queriedPost):
                result = TestPost3(model: queriedPost)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, content: String, post: TestPost3, plugin: AWSDataStorePlugin) throws -> TestComment4? {
        let comment = try TestComment4(id: id, content: "content", post: post.model)
        var result: TestComment4?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(comment.model, modelSchema: Comment4.schema) { event in
            switch event {
            case .success(let queriedComment):
                result = TestComment4(model: queriedComment)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
