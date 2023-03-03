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
@testable import DataStoreHostApp

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
        try await comments.fetch()
        XCTAssertEqual(comments.count, 2)
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment1post1.id
        }))
        XCTAssertTrue(comments.contains(where: { (comment) -> Bool in
            comment.id == comment2post1.id
        }))
        if let post = comments[0].post, let comments = post.comments {
            try await comments.fetch()
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
            try await postsInEagerlyLoadedBlog.fetch()
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
        try await lazilyLoadedComments.fetch()
        XCTAssertEqual(lazilyLoadedComments.count, 1)
        XCTAssertEqual(lazilyLoadedComments[0].id, comment.id)
        if let fetchedPost = lazilyLoadedComments[0].post, let comments = fetchedPost.comments {
            XCTAssertEqual(fetchedPost.id, post.id)
            try await comments.fetch()
            XCTAssertEqual(comments.count, 1)
        }
    }

    /// Ensure that the delete with `.all` predicate works as expected.
    /// There may be additional blogs/post/comments from other tests that are being deleted as part of this test
    /// We ignore those and only assert that that 6 models created in this test were deleted successfully.
    func testDeleteAll() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        var cancellables = Set<AnyCancellable>()
        let remoteEventReceived = expectation(description: "received mutation event with version 1")
        remoteEventReceived.expectedFulfillmentCount = 2
        let commentId1 = UUID().uuidString
        let commentId2 = UUID().uuidString
        
        let task = Task {
            let mutationEvents = Amplify.DataStore.observe(Comment6.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.modelId == commentId1 && mutationEvent.version == 1 {
                        remoteEventReceived.fulfill()
                    }
                    if mutationEvent.modelId == commentId2 && mutationEvent.version == 1 {
                        remoteEventReceived.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        let blog = try await saveBlog(name: "name")
        let post = try await savePost(title: "title", blog: blog)
        _ = try await saveComment(id: commentId1, post: post, content: "content")
        let blog2 = try await saveBlog(name: "name")
        let post2 = try await savePost(title: "title", blog: blog2)
        _ = try await saveComment(id: commentId2, post: post2, content: "content")

        await waitForExpectations(timeout: 10)

        let outboxMutationProcessed = expectation(description: "received outboxMutationProcessed")
        var processedSoFar = 0
        Amplify.Hub.publisher(for: .dataStore)
            .sink { payload in
                let event = DataStoreHubEvent(payload: payload)
                switch event {
                case .outboxMutationProcessed(let mutationEvent):
                    if mutationEvent.modelName == Blog6.modelName,
                       let model = mutationEvent.element.model as? Blog6,
                       model.id == blog.id || model.id == blog2.id {
                        processedSoFar += 1
                    } else if mutationEvent.modelName == Post6.modelName,
                              let model = mutationEvent.element.model as? Post6,
                              model.id == post.id || model.id == post2.id {
                        processedSoFar += 1
                    } else if mutationEvent.modelName == Comment6.modelName,
                              let model = mutationEvent.element.model as? Comment6,
                              model.id == commentId1 || model.id == commentId2 {
                        processedSoFar += 1
                    }
                    
                    Amplify.Logging.verbose("Processed so far \(processedSoFar)/6")
                    if processedSoFar == 6 {
                        outboxMutationProcessed.fulfill()
                    }
                default:
                    break
                }
            }.store(in: &cancellables)
        
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
