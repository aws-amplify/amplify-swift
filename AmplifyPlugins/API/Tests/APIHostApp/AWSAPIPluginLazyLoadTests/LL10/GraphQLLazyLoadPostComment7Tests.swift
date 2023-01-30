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

final class GraphQLLazyLoadPostComment7Tests: GraphQLLazyLoadBaseTest {

    func testSave() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post should be lazy loaded
    func testCommentWithLazyLoadPost() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment))
        
        // The comment's post should not be loaded, since no `includes` is passed in.
        // And the codegenerated swift models have the new modelPath properties.
        assertLazyReference(createdComment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: createdPost.postId),
                                                                                  .init(name: "title", value: post.title)]))
        let loadedPost = try await createdComment.post!
        XCTAssertEqual(loadedPost.postId, createdPost.postId)
        XCTAssertEqual(loadedPost.title, createdPost.title)
        
        let comments = loadedPost.comments!
        // The loaded post should have comments that are also not loaded
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [createdPost.postId, createdPost.title], associatedField: "post"))
        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        // the loaded comment's post should not be loaded
        assertLazyReference(comments.first!._post, state: .notLoaded(identifiers: [.init(name: "postId", value: createdPost.postId),
                                                                                   .init(name: "title", value: createdPost.title)]))
    }
    
    // With `includes` on `comment.post`, the comment's post should be eager loaded.
    func testCommentWithEagerLoadPost() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        // The comment's post should be loaded, since `includes` include the post
        assertLazyReference(createdComment._post, state: .loaded(model: createdPost))
        let loadedPost = try await createdComment.post!
        XCTAssertEqual(loadedPost.postId, post.postId)
        // The loaded post should have comments that are not loaded
        let comments = loadedPost.comments!
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [createdPost.postId, createdPost.title], associatedField: "post"))
        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        // further nested models should not be loaded
        assertLazyReference(comments.first!._post, state: .notLoaded(identifiers: [.init(name: "postId", value: createdPost.postId),
                                                                                   .init(name: "title", value: createdPost.title)]))
    }
    
    func testQueryThenLazyLoad() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        try await assertComment(queriedComment, canLazyLoad: savedPost)
        let queriedPost = try await query(.get(Post.self, byIdentifier: .identifier(postId: post.postId, title: post.title)))!
        try await assertPost(queriedPost, canLazyLoad: savedComment)
    }
    
    func testListPostsListComments() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
        
        let queriedPosts = try await listQuery(.list(Post.self, where: Post.keys.postId == post.postId))
        assertList(queriedPosts, state: .isLoaded(count: 1))
        assertList(queriedPosts.first!.comments!,
                   state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title], associatedField: "post"))
        
        let queriedComments = try await listQuery(.list(Comment.self, where: Comment.keys.commentId == comment.commentId))
        assertList(queriedComments, state: .isLoaded(count: 1))
        assertLazyReference(queriedComments.first!._post,
                            state: .notLoaded(identifiers: [
                                .init(name: "postId", value: post.postId),
                                .init(name: "title", value: "title")]))
    }
    
    func assertComment(_ comment: Comment,
                       hasEagerLoaded post: Post) async throws {
        assertLazyReference(comment._post,
                        state: .loaded(model: post))
        
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.postId, post.postId)
        
        try await assertPost(loadedPost, canLazyLoad: comment)
    }
    
    func assertComment(_ comment: Comment,
                       canLazyLoad post: Post) async throws {
        assertLazyReference(comment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                            .init(name: "title", value: post.title)]))
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to load the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.postId, post.postId)
        assertLazyReference(comment._post,
                        state: .loaded(model: post))
        try await assertPost(loadedPost, canLazyLoad: comment)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad comment: Comment) async throws {
        guard let comments = post.comments else {
            XCTFail("Missing comments on post")
            return
        }
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title],
                                                 associatedField: "post"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertLazyReference(comment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                            .init(name: "title", value: post.title)]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment7Models())
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await mutate(.create(post))
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithPost)!
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        assertLazyReference(queriedComment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                                  .init(name: "title", value: post.title)]))
        let savedQueriedComment = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: savedQueriedComment)!
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        assertLazyReference(queriedComment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                                  .init(name: "title", value: post.title)]))
        
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await mutate(.create(newPost))
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithNewPost)!
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId,
                                                                                          content: comment.content)))!
        assertLazyReference(queriedComment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                                  .init(name: "title", value: post.title)]))
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)!
        assertLazyReference(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        try await mutate(.delete(savedPost))
        try await assertModelDoesNotExist(savedPost)
        try await assertModelExists(savedComment)
        try await mutate(.delete(savedComment))
        try await assertModelDoesNotExist(savedComment)
    }
}

extension GraphQLLazyLoadPostComment7Tests: DefaultLogger { }

extension GraphQLLazyLoadPostComment7Tests {
    typealias Post = Post7
    typealias Comment = Comment7
    
    struct PostComment7Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post7.self)
            ModelRegistry.register(modelType: Comment7.self)
        }
    }
}
