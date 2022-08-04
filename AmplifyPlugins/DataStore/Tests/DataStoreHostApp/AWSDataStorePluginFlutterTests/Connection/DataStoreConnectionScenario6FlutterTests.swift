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
 ```
 # 6 - Blog Post Comment
 type Blog6 @model {
   id: ID!
   name: String!
   posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
 }
 type Post6 @model @key(name: "byBlog", fields: ["blogID"]) {
   id: ID!
   title: String!
   blogID: ID!
   blog: Blog6 @connection(fields: ["blogID"])
   comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
 }
 type Comment6 @model @key(name: "byPost", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   post: Post6 @connection(fields: ["postID"])
   content: String!
 }
 ```
 */

class DataStoreConnectionScenario6FlutterTests: SyncEngineFlutterIntegrationTestBase {
    /// TODO: Implement testGetBlogThenFetchPostsThenFetchComments
    func testGetCommentThenFetchPostThenFetchBlog() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let blog = try saveBlog(name: "name", plugin: plugin),
              let post = try savePost(title: "title", blog: blog, plugin: plugin),
              let comment = try saveComment(post: post, content: "content", plugin: plugin) else {
            XCTFail("Could not create blog, post, and comment")
            return
        }
        let getCommentCompleted = expectation(description: "get comment complete")
        var resultComment: Comment6Wrapper?
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment6.schema, where: Comment6.keys.id.eq(comment.idString())) { result in
            switch result {
            case .success(let queriedCommentOptional):
                let queriedComment = Comment6Wrapper(model: queriedCommentOptional[0])
                XCTAssertEqual(queriedComment.id(), comment.id())
                resultComment = queriedComment
                getCommentCompleted.fulfill()
            case .failure(let response):
                XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let fetchedComment = resultComment else {
            XCTFail("Could not get comment")
            return
        }
        guard let fetchedPost = fetchedComment.post() else {
            XCTFail("Post is nil, should be loaded")
            return
        }
        guard let fetchedBlog = fetchedPost["blog"] else {
            XCTFail("Blog is nil, should be loaded")
            return
        }
        XCTAssertEqual(fetchedPost["id"], post.id())
        XCTAssertEqual(fetchedPost["title"], post.title())
        XCTAssertEqual(fetchedBlog["id"], blog.id())
        XCTAssertEqual(fetchedBlog["name"], blog.name())
    }

    /// TODO: Include testGetPostThenFetchBlogAndComment when nested model lazy loading is implemented
    func saveBlog(id: String = UUID().uuidString, name: String, plugin: AWSDataStorePlugin) throws -> Blog6Wrapper? {
        let blog = try Blog6Wrapper(name: name)
        var result: Blog6Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(blog.model, modelSchema: Blog6.schema) { event in
            switch event {
            case .success(let data):
                result = Blog6Wrapper(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6Wrapper, plugin: AWSDataStorePlugin) throws -> Post6Wrapper? {
        let post = try Post6Wrapper(title: title, blog: blog.model)
        var result: Post6Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post6.schema) { event in
            switch event {
            case .success(let data):
                result = Post6Wrapper(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, post: Post6Wrapper, content: String, plugin: AWSDataStorePlugin) throws -> Comment6Wrapper? {
        let comment = try Comment6Wrapper(content: content, post: post.model)
        var result: Comment6Wrapper?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(comment.model, modelSchema: Comment6.schema) { event in
            switch event {
            case .success(let data):
                result = Comment6Wrapper(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
