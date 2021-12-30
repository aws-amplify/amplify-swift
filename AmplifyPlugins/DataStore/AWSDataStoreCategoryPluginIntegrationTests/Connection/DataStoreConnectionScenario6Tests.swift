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

class DataStoreConnectionScenario6Tests: SyncEngineIntegrationTestBase {

    func testGetBlogThenFetchPostsThenFetchComments() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post1 = savePost(title: "title", blog: blog),
              let post2 = savePost(title: "title", blog: blog),
              let comment1post1 = saveComment(post: post1, content: "content"),
              let comment2post1 = saveComment(post: post1, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        var resultPosts: List<Post6>?
        Amplify.DataStore.query(Blog6.self, byId: blog.id) { result in
            switch result {
            case .success(let queriedBlogOptional):
                guard let queriedBlog = queriedBlogOptional else {
                    XCTFail("Could not get blog")
                    return
                }
                XCTAssertEqual(queriedBlog.id, blog.id)
                resultPosts = queriedBlog.posts
                getBlogCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }
        wait(for: [getBlogCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let posts = resultPosts else {
            XCTFail("Could not get posts")
            return
        }
        XCTAssertEqual(posts.count, 2)
        guard let fetchedPost = posts.first(where: { (post) -> Bool in
            post.id == post1.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }
        XCTAssertEqual(comments.count, 2)
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
        if let post = comments[0].post {
            XCTAssertEqual(post.comments?.count, 2)
        }
    }

    func testGetCommentThenFetchPostThenFetchBlog() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        var resultComment: Comment6?
        Amplify.DataStore.query(Comment6.self, byId: comment.id) { result in
            switch result {
            case .success(let queriedCommentOptional):
                guard let queriedComment = queriedCommentOptional else {
                    XCTFail("Could not get comment")
                    return
                }
                XCTAssertEqual(queriedComment.id, comment.id)
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

        guard let fetchedPost = fetchedComment.post else {
            XCTFail("Post is nil, should be loaded")
            return
        }

        guard let fetchedBlog = fetchedPost.blog else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(fetchedPost.id, post.id)
        XCTAssertEqual(fetchedPost.title, post.title)

        XCTAssertEqual(fetchedBlog.id, blog.id)
        XCTAssertEqual(fetchedBlog.name, blog.name)
    }

    func testGetPostThenFetchBlogAndComment() throws {
        try startAmplifyAndWaitForSync()
        guard let blog = saveBlog(name: "name"),
              let post = savePost(title: "title", blog: blog),
              let comment = saveComment(post: post, content: "content") else {
            XCTFail("Could not create blog, post, and comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        var resultPost: Post6?
        Amplify.DataStore.query(Post6.self, byId: post.id) { result in
            switch result {
            case .success(let queriedPostOptional):
                guard let queriedPost = queriedPostOptional else {
                    XCTFail("Could not get post")
                    return
                }
                XCTAssertEqual(queriedPost.id, post.id)
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

        guard let eagerlyLoadedBlog = fetchedPost.blog else {
            XCTFail("Blog is nil, should be loaded")
            return
        }

        XCTAssertEqual(eagerlyLoadedBlog.id, blog.id)
        XCTAssertEqual(eagerlyLoadedBlog.name, blog.name)
        if let postsInEagerlyLoadedBlog = eagerlyLoadedBlog.posts {
            XCTAssertEqual(postsInEagerlyLoadedBlog.count, 1)
            XCTAssertTrue(postsInEagerlyLoadedBlog.contains(where: {(postIn) -> Bool in
                postIn.id == post.id
            }))
            XCTAssertEqual(postsInEagerlyLoadedBlog[0].id, post.id)
        }

        guard let lazilyLoadedComments = fetchedPost.comments else {
            XCTFail("Could not get comments")
            return
        }

        guard case .notLoaded = lazilyLoadedComments.loadedState else {
            XCTFail("Should not be in loaded state")
            return
        }
        XCTAssertEqual(lazilyLoadedComments.count, 1)
        XCTAssertEqual(lazilyLoadedComments[0].id, comment.id)
        if let fetchedPost = lazilyLoadedComments[0].post {
            XCTAssertEqual(fetchedPost.id, post.id)
            XCTAssertEqual(fetchedPost.comments?.count, 1)
        }
    }

    func saveBlog(id: String = UUID().uuidString, name: String) -> Blog6? {
        let blog = Blog6(id: id, name: name)
        var result: Blog6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(blog) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6) -> Post6? {
        let post = Post6(id: id, title: title, blog: blog)
        var result: Post6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(post) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func saveComment(id: String = UUID().uuidString, post: Post6, content: String) -> Comment6? {
        let comment = Comment6(id: id, post: post, content: content)
        var result: Comment6?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(comment) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
