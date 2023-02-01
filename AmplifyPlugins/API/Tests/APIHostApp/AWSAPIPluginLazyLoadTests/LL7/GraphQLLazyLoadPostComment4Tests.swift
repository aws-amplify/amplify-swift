//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

final class GraphQLLazyLoadPostComment4Tests: GraphQLLazyLoadBaseTest {

    func testSave() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post should be lazy loaded
    func testCommentWithLazyLoadPost() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment))
        
        XCTAssertEqual(createdComment.post4CommentsPostId, post.postId)
        XCTAssertEqual(createdComment.post4CommentsTitle, post.title)
        
        // The created post should have comments that are also not loaded
        let comments = createdPost.comments!
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [createdPost.postId,
                                                                         createdPost.title],
                                                 associatedField: "post4CommentsPostId"))
        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        XCTAssertEqual(comments.first!.post4CommentsPostId, post.postId)
        XCTAssertEqual(comments.first!.post4CommentsTitle, post.title)
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post's comments should be lazy loaded
    func testPostWithLazyLoadComments() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        let queriedPost = try await query(.get(Post.self, byIdentifier: .identifier(postId: post.postId, title: post.title)))!
        let comments = queriedPost.comments!
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title], associatedField: "post4CommentsPostId"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        XCTAssertEqual(comments.first!.post4CommentsPostId, post.postId)
        XCTAssertEqual(comments.first!.post4CommentsTitle, post.title)
    }
    
    // With `includes` on `post.comments` should eager load the post's comments
    func testPostWithEagerLoadComments() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        let queriedPost = try await query(.get(Post.self, byIdentifier: .identifier(postId: post.postId, title: post.title), includes: { post in [post.comments]}))!
        let comments = queriedPost.comments!
        assertList(comments, state: .isLoaded(count: 1))
        XCTAssertEqual(comments.first!.post4CommentsPostId, post.postId)
        XCTAssertEqual(comments.first!.post4CommentsTitle, post.title)
    }
    
    func testListPostsListComments() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        
        let queriedPosts = try await listQuery(.list(Post.self, where: Post.keys.postId == post.postId))
        assertList(queriedPosts, state: .isLoaded(count: 1))
        assertList(queriedPosts.first!.comments!,
                   state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title], associatedField: "post4CommentsPostId"))
        
        let queriedComments = try await listQuery(.list(Comment.self, where: Comment.keys.commentId == comment.commentId))
        assertList(queriedComments, state: .isLoaded(count: 1))
        XCTAssertEqual(queriedComments.first!.post4CommentsPostId, post.postId)
        XCTAssertEqual(queriedComments.first!.post4CommentsTitle, post.title)
    }
    
    func testCreateWithoutPost() async throws {
        await setup(withModels: PostComment4Models())
        let comment = Comment(content: "content")
        try await mutate(.create(comment))
        var queriedComment = try await query(for: comment)!
        XCTAssertEqual(queriedComment.post4CommentsPostId, nil)
        XCTAssertEqual(queriedComment.post4CommentsTitle, nil)
        let post = Post(title: "title")
        let createdPost = try await mutate(.create(post))
        queriedComment.post4CommentsTitle = nil
        queriedComment.post4CommentsPostId = nil
        let updateCommentWithPost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(for: updateCommentWithPost)!
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsPostId, post.postId)
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsTitle, post.title)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        XCTAssertEqual(queriedComment.post4CommentsPostId, post.postId)
        XCTAssertEqual(queriedComment.post4CommentsTitle, post.title)
        let newPost = Post(title: "title")
        let createdNewPost = try await mutate(.create(newPost))
        queriedComment.post4CommentsPostId = newPost.postId
        queriedComment.post4CommentsTitle = newPost.title
        let updateCommentWithPost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(for: updateCommentWithPost)!
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsPostId, newPost.postId)
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsTitle, newPost.title)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
        var queriedComment = try await query(for: comment)!
        XCTAssertEqual(queriedComment.post4CommentsPostId, post.postId)
        XCTAssertEqual(queriedComment.post4CommentsTitle, post.title)
        
        queriedComment.post4CommentsPostId = nil
        queriedComment.post4CommentsTitle = nil
        let updateCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(for: updateCommentRemovePost)!
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsPostId, nil)
        XCTAssertEqual(queriedCommentAfterUpdate.post4CommentsTitle, nil)
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        try await mutate(.create(comment))
            
        try await mutate(.delete(createdPost))
        let queriedPost = try await query(for: post)
        XCTAssertNil(queriedPost)
        let queriedComment = try await query(for: comment)!
        XCTAssertEqual(queriedComment.post4CommentsPostId, createdPost.postId)
        XCTAssertEqual(queriedComment.post4CommentsTitle, createdPost.title)
        try await mutate(.delete(queriedComment))
        let queryDeletedComment = try await query(for: comment)
        XCTAssertNil(queryDeletedComment)
    }
    
    func testSubscribeToComments() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        try await mutate(.create(post))
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedComment = asyncExpectation(description: "onCreatedComment received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Comment.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdComment):
                            log.verbose("Successfully got createdComment from subscription: \(createdComment)")
                            XCTAssertEqual(createdComment.post4CommentsPostId, post.postId)
                            XCTAssertEqual(createdComment.post4CommentsTitle, post.title)
                            await onCreatedComment.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(comment))
        await waitForExpectations([onCreatedComment], timeout: 10)
        subscription.cancel()
    }
    
    func testSubscribeToPosts() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedPost = asyncExpectation(description: "onCreatedPost received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdPost):
                            log.verbose("Successfully got createdPost from subscription: \(createdPost)")
                            assertList(createdPost.comments!, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title], associatedField: "post4CommentsPostId"))
                            await onCreatedPost.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(post))
        await waitForExpectations([onCreatedPost], timeout: 10)
        subscription.cancel()
    }
    
    func testSubscribeToPostsIncludes() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(title: "title")
        
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedPost = asyncExpectation(description: "onCreatedPost received")
        let subscriptionIncludes = Amplify.API.subscribe(request: .subscription(of: Post.self,
                                                                                type: .onCreate,
                                                                                includes: { post in [post.comments]}))
        Task {
            do {
                for try await subscriptionEvent in subscriptionIncludes {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdPost):
                            log.verbose("Successfully got createdPost from subscription: \(createdPost)")
                            assertList(createdPost.comments!, state: .isLoaded(count: 0))
                            await onCreatedPost.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(post, includes: { post in [post.comments]}))
        await waitForExpectations([onCreatedPost], timeout: 10)
        subscriptionIncludes.cancel()
    }
}

extension GraphQLLazyLoadPostComment4Tests: DefaultLogger { }

extension GraphQLLazyLoadPostComment4Tests {
    typealias Post = Post4
    typealias Comment = Comment4
    
    struct PostComment4Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post4.self)
            ModelRegistry.register(modelType: Comment4.self)
        }
    }
}

extension Post4 {
    init(title: String) {
        self.init(postId: UUID().uuidString, title: title)
    }
}

extension Comment4 {
    init(content: String,
         post: Post4? = nil) {
        self.init(commentId: UUID().uuidString,
                  content: content,
                  post4CommentsPostId: post?.postId,
                  post4CommentsTitle: post?.title)
    }
}
