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

//    func testGetBlogThenFetchPostsThenFetchComments() throws {
//        try startAmplifyAndWaitForSync()
//        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
//        guard let blog = try saveBlog(name: "name", plugin: plugin),
//              let post1 = try savePost(title: "title", blog: blog, plugin: plugin),
//              let post2 = try savePost(title: "title", blog: blog, plugin: plugin),
//              let comment1post1 = try saveComment(post: post1, content: "content", plugin: plugin),
//              let comment2post1 = try saveComment(post: post1, content: "content", plugin: plugin) else {
//            XCTFail("Could not create blog, posts, and comments")
//            return
//        }
//        let getBlogCompleted = expectation(description: "get blog complete")
//        var resultPosts: List<Flutter>?
//        plugin.query(FlutterSerializedModel.self, modelSchema: Blog6.schema, where: Blog6.keys.id.eq(blog.idString())) { result in
//            switch result {
//            case .success(let queriedBlogOptional):
//                guard let queriedBlog = queriedBlogOptional else {
//                    XCTFail("Could not get blog")
//                    return
//                }
//                let queriedBlog = TestBlog6(model: queriedBlogOptional[0])
//                XCTAssertEqual(queriedBlog.id(), blog.id())
//                resultPosts = queriedBlog.posts()
//                getBlogCompleted.fulfill()
//            case .failure(let response): XCTFail("Failed with: \(response)")
//            }
//        }
//        wait(for: [getBlogCompleted], timeout: TestCommonConstants.networkTimeout)
//        guard let posts = resultPosts else {
//            XCTFail("Could not get posts")
//            return
//        }
//        XCTAssertEqual(posts.count, 2)
//        guard let fetchedPost = posts.first(where: { (post) -> Bool in
//            post.id == post1.id
//        }), let comments = fetchedPost.comments else {
//            XCTFail("Could not set up - failed to get a post and its comments")
//            return
//        }
//        XCTAssertEqual(comments.count, 2)
//        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
//            comment.id == comment1post1.id
//        }))
//        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
//            comment.id == comment2post1.id
//        }))
//        if let post = comments[0].post {
//            XCTAssertEqual(post.comments?.count, 2)
//        }
//    }

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
        var resultComment: TestComment6?
        plugin.query(FlutterSerializedModel.self, modelSchema: Comment6.schema, where: Comment6.keys.id.eq(comment.idString())) { result in
            switch result {
            case .success(let queriedCommentOptional):
                let queriedComment = TestComment6(model: queriedCommentOptional[0])
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

    func testGetPostThenFetchBlogAndComment() throws {
        try startAmplifyAndWaitForSync()
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        guard let blog = try saveBlog(name: "name", plugin: plugin),
              let post = try savePost(title: "title", blog: blog, plugin: plugin),
              let comment = try saveComment(post: post, content: "content", plugin: plugin) else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        var resultPost: TestPost6?
        plugin.query(FlutterSerializedModel.self, modelSchema: Post6.schema, where: Post6.keys.id.eq(post.idString())) { result in
            switch result {
            case .success(let queriedPostOptional):
                let queriedPost = TestPost6(model: queriedPostOptional[0])
                XCTAssertEqual(queriedPost.id(), post.id())
                resultPost = queriedPost
                getPostCompleted.fulfill()
            case .failure(let response):
                XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)

        guard let fetchedPost = resultPost else {
            XCTFail("Could not get post")
            return
        }

        guard let eagerlyLoadedBlog = fetchedPost.blog() else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(eagerlyLoadedBlog["id"], blog.id())
        XCTAssertEqual(eagerlyLoadedBlog["name"], blog.name())
//        if let postsInEagerlyLoadedBlog = eagerlyLoadedBlog.posts {
//            XCTAssertEqual(postsInEagerlyLoadedBlog.count, 1)
//            XCTAssertTrue(postsInEagerlyLoadedBlog.contains(where: {(postIn) -> Bool in
//                postIn.id == post.id
//            }))
//            XCTAssertEqual(postsInEagerlyLoadedBlog[0].id, post.id)
//        }

//        guard let lazilyLoadedComments = fetchedPost.comments else {
//            XCTFail("Could not get comments")
//            return
//        }
//
//        guard case .notLoaded = lazilyLoadedComments.loadedState else {
//            XCTFail("Should not be in loaded state")
//            return
//        }
//        XCTAssertEqual(lazilyLoadedComments.count, 1)
//        XCTAssertEqual(lazilyLoadedComments[0].id, comment.id)
//        if let fetchedPost = lazilyLoadedComments[0].post {
//            XCTAssertEqual(fetchedPost.id, post.id)
//            XCTAssertEqual(fetchedPost.comments?.count, 1)
//        }
    }

    func saveBlog(id: String = UUID().uuidString, name: String, plugin: AWSDataStorePlugin) throws -> TestBlog6? {
        let blog = try TestBlog6(name: name)
        var result: TestBlog6?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(blog.model, modelSchema: Blog6.schema) { event in
            switch event {
            case .success(let data):
                result = TestBlog6(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: TestBlog6, plugin: AWSDataStorePlugin) throws -> TestPost6? {
        let post = try TestPost6(title: title, blog: blog.model)
        var result: TestPost6?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(post.model, modelSchema: Post6.schema) { event in
            switch event {
            case .success(let data):
                result = TestPost6(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, post: TestPost6, content: String, plugin: AWSDataStorePlugin) throws -> TestComment6? {
        let comment = try TestComment6(content: content, post: post.model)
        var result: TestComment6?
        let completeInvoked = expectation(description: "request completed")
        plugin.save(comment.model, modelSchema: Comment6.schema) { event in
            switch event {
            case .success(let data):
                result = TestComment6(model: data)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
