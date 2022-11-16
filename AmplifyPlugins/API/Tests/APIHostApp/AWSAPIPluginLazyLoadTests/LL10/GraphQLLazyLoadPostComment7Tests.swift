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
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post should be lazy loaded
    func testCommentWithLazyLoadPost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment))
        // The comment's post should not be loaded, since no `includes` is passed in.
        // And the codegenerated swift models have the new modelPath properties.
        assertLazyModel(createdComment._post, state: .notLoaded(identifiers: [.init(name: "postId", value: createdPost.postId)]))
        let loadedPost = try await createdComment.post!
        XCTAssertEqual(loadedPost.postId, createdPost.postId)
        //let comments = loadedPost.comments!
        // The loaded post should have comments that are also not loaded
        //assertList(comments, state: .isNotLoaded(associatedId: createdPost.postId, associatedField: "post"))
        // load the comments
        //try await comments.fetch()
        //assertList(comments, state: .isLoaded(count: 1))
        // the loaded comment's post should not be loaded
        //assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["postId": createdPost.postId]))
    }
    
    // With `includes` on `comment.post`, the comment's post should be eager loaded.
    func testCommentWithEagerLoadPost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        // The comment's post should be loaded, since `includes` include the post
        assertLazyModel(createdComment._post, state: .loaded(model: createdPost))
        let loadedPost = try await createdComment.post!
        //XCTAssertEqual(loadedPost.postId, post.postId)
        // The loaded post should have comments that are not loaded
        //let comments = loadedPost.comments!
        //assertList(comments, state: .isNotLoaded(associatedId: post.identifier, associatedField: "post"))
        // load the comments
        //try await comments.fetch()
        //assertList(comments, state: .isLoaded(count: 1))
        // further nested models should not be loaded
        //assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
        try await assertComment(queriedComment, canLazyLoad: savedPost)
        let queriedPost = try await query(.get(Post.self, byId: post.postId))!
        try await assertPost(queriedPost, canLazyLoad: savedComment)
    }
    
    func assertComment(_ comment: Comment,
                       hasEagerLoaded post: Post) async throws {
        assertLazyModel(comment._post,
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
        assertLazyModel(comment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to load the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.postId, post.postId)
        assertLazyModel(comment._post,
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
        assertLazyModel(comment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await mutate(.create(post))
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithPost)!
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        let queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        let savedQueriedComment = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: savedQueriedComment)!
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await mutate(.create(newPost))
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithNewPost)!
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)!
        assertLazyModel(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        try await mutate(.delete(savedPost))
        try await assertModelDoesNotExist(savedComment)
        try await assertModelDoesNotExist(savedPost)
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
