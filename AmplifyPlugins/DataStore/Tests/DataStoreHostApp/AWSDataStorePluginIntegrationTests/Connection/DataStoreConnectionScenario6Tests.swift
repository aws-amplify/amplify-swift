//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine
@testable import Amplify
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

@available(iOS 13.0, *)
class DataStoreConnectionScenario6Tests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Blog6.self)
            registry.register(modelType: Post6.self)
            registry.register(modelType: Comment6.self)
        }

        let version: String = "1"
    }

    func testGetBlogThenFetchPostsThenFetchComments() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let blog = try await saveBlog(name: "name")
        let post1 = try await savePost(title: "title", blog: blog)
        _ = try await savePost(title: "title", blog: blog)
        let comment1post1 = try await saveComment(post: post1, content: "content")
        let comment2post1 = try await saveComment(post: post1, content: "content")

        let queriedBlogOptional = try await Amplify.DataStore.query(Blog6.self, byId: blog.id)
        guard let queriedBlog = queriedBlogOptional else {
            XCTFail("Could not get blog")
            return
        }
        XCTAssertEqual(queriedBlog.id, blog.id)
        guard let posts = queriedBlog.posts else {
            XCTFail("Could not get posts")
            return
        }
        try await posts.fetch()
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

    func testGetCommentThenFetchPostThenFetchBlog() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let blog = try await saveBlog(name: "name")
        let post = try await savePost(title: "title", blog: blog)
        let comment = try await saveComment(post: post, content: "content")

        let queriedCommentOptional = try await Amplify.DataStore.query(Comment6.self, byId: comment.id)
        guard let queriedComment = queriedCommentOptional else {
            XCTFail("Could not get comment")
            return
        }
        XCTAssertEqual(queriedComment.id, comment.id)

        guard let fetchedPost = queriedComment.post else {
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

    func testGetPostThenFetchBlogAndComment() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let blog = try await saveBlog(name: "name")
        let post = try await savePost(title: "title", blog: blog)
        let comment = try await saveComment(post: post, content: "content")
        let queriedPostOptional = try await Amplify.DataStore.query(Post6.self, byId: post.id)
        guard let queriedPost = queriedPostOptional else {
            XCTFail("Could not get post")
            return
        }
        XCTAssertEqual(queriedPost.id, post.id)

        guard let eagerlyLoadedBlog = queriedPost.blog else {
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

        guard let lazilyLoadedComments = queriedPost.comments else {
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

    func testDeleteAll() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        var cancellables = Set<AnyCancellable>()
        let remoteEventReceived = expectation(description: "received mutation event with version 1")
        let commentId = UUID().uuidString
        Amplify.DataStore.publisher(for: Comment6.self).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        } receiveValue: { mutationEvent in
            if mutationEvent.modelId == commentId && mutationEvent.version == 1 {
                remoteEventReceived.fulfill()
            }
        }.store(in: &cancellables)
        let blog = try await saveBlog(name: "name")
        let post = try await savePost(title: "title", blog: blog)
        _ = try await saveComment(id: commentId, post: post, content: "content")

        await waitForExpectations(timeout: 5)

        let blogs = try await Amplify.DataStore.query(Blog6.self)
        var blogCount = blogs.count
        let posts = try await Amplify.DataStore.query(Post6.self)
        var postCount = posts.count

        let retrievedCommentCount = expectation(description: "retrieved comment count")
        let comments = try await Amplify.DataStore.query(Comment6.self)
        var commentCount = comments.count

        let totalCount = blogCount + postCount + commentCount
        Amplify.Logging.verbose("Retrieved blog \(blogCount) post \(postCount) comment \(commentCount)")

        let outboxMutationProcessed = expectation(description: "received outboxMutationProcessed")
        var processedSoFar = 0
        Amplify.Hub.publisher(for: .dataStore)
            .sink { payload in
                let event = DataStoreHubEvent(payload: payload)
                switch event {
                case .outboxMutationProcessed:
                    processedSoFar += 1
                    print("Processed so far \(processedSoFar)")
                    if processedSoFar == totalCount {
                        outboxMutationProcessed.fulfill()
                    }
                default:
                    break
                }
            }.store(in: &cancellables)

        let deleteSuccess = expectation(description: "Delete all successful")
        try await Amplify.DataStore.delete(Blog6.self, where: QueryPredicateConstant.all)

        await waitForExpectations(timeout: 10)
    }

    func saveBlog(id: String = UUID().uuidString, name: String) async throws -> Blog6 {
        let blog = Blog6(id: id, name: name)
        return try await Amplify.DataStore.save(blog)
    }

    func savePost(id: String = UUID().uuidString, title: String, blog: Blog6) async throws -> Post6 {
        let post = Post6(id: id, title: title, blog: blog)
        return try await Amplify.DataStore.save(post)
    }

    func saveComment(id: String = UUID().uuidString, post: Post6, content: String) async throws -> Comment6 {
        let comment = Comment6(id: id, post: post, content: content)
        return try await Amplify.DataStore.save(comment)
    }
}
