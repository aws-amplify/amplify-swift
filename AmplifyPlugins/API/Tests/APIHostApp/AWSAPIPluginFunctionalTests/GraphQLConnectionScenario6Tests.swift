//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

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
class GraphQLConnectionScenario6Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Blog6.self)
            ModelRegistry.register(modelType: Post6.self)
            ModelRegistry.register(modelType: Comment6.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testGetBlogThenFetchPostsThenFetchComments() async throws {
        guard let blog = try await createBlog(name: "name"),
              let post1 = try await createPost(title: "title", blog: blog),
              try await createPost(title: "title", blog: blog) != nil,
              let comment1post1 = try await createComment(post: post1, content: "content"),
              let comment2post1 = try await createComment(post: post1, content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let getBlogCompleted = expectation(description: "get blog complete")
        let fetchPostCompleted = expectation(description: "fetch post complete")
        var resultPosts: List<Post6>?
        let response = try await Amplify.API.query(request: .get(Blog6.self, byId: blog.id))
        switch response {
        case .success(let queriedBlogOptional):
            guard let queriedBlog = queriedBlogOptional else {
                XCTFail("Could not get blog")
                return
            }
            XCTAssertEqual(queriedBlog.id, blog.id)
            getBlogCompleted.fulfill()
            guard let posts = queriedBlog.posts else {
                XCTFail("Could not get comments")
                return
            }
            try await posts.fetch()
            resultPosts = posts
            fetchPostCompleted.fulfill()
        case .failure(let response): XCTFail("Failed with: \(response)")
        }
        wait(for: [getBlogCompleted, fetchPostCompleted], timeout: TestCommonConstants.networkTimeout)

        let allPosts = try await getAll(list: resultPosts)
        XCTAssertEqual(allPosts.count, 2)
        guard let fetchedPost = allPosts.first(where: { (post) -> Bool in
            post.id == post1.id
        }), let comments = fetchedPost.comments else {
            XCTFail("Could not set up - failed to get a post and its comments")
            return
        }

        let fetchCommentsCompleted = expectation(description: "fetch post complete")
        var resultComments: List<Comment6>?
        try await comments.fetch()
        resultComments = comments
        fetchCommentsCompleted.fulfill()
        wait(for: [fetchCommentsCompleted], timeout: TestCommonConstants.networkTimeout)
        let allComments = try await getAll(list: resultComments)
        XCTAssertEqual(allComments.count, 2)
        XCTAssertTrue(allComments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(allComments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
    }

    func getAll<M>(list: List<M>?) async throws -> [M] {
        guard var list = list else {
            return []
        }
        var results = [M]()
        results.append(contentsOf: list.elements)
        while list.hasNextPage() {
            let nextList = try await list.getNextPage()
            list = nextList
            results.append(contentsOf: nextList.elements)
        }
        return results
    }

    func createBlog(id: String = UUID().uuidString, name: String) async throws -> Blog6? {
        let blog = Blog6(id: id, name: name)
        let data = try await Amplify.API.mutate(request: .create(blog))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }

    func createPost(id: String = UUID().uuidString, title: String, blog: Blog6) async throws -> Post6? {
        let post = Post6(id: id, title: title, blog: blog)
        let data = try await Amplify.API.mutate(request: .create(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }

    func createComment(id: String = UUID().uuidString, post: Post6, content: String) async throws -> Comment6? {
        let comment = Comment6(id: id, post: post, content: content)
        let data = try await Amplify.API.mutate(request: .create(comment))
        switch data {
        case .success(let comment):
            return comment
        case .failure(let error):
            throw error
        }
    }
}
