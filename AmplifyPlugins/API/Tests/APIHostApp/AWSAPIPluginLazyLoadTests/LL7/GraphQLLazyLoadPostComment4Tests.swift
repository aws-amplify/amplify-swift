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

    func testLazyLoad() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        assertComment(savedComment, contains: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(for: comment)!
        assertComment(queriedComment, contains: savedPost)
        let queriedPost = try await query(for: post)!
        try await assertPost(queriedPost, canLazyLoad: savedComment)
    }
    
    func assertComment(_ comment: Comment, contains post: Post) {
        XCTAssertEqual(comment.post4CommentsPostId, post.postId)
        XCTAssertEqual(comment.post4CommentsTitle, post.title)
    }
    
    func assertCommentDoesNotContainPost(_ comment: Comment) {
        XCTAssertNil(comment.post4CommentsPostId)
        XCTAssertNil(comment.post4CommentsTitle)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad comment: Comment) async throws {
        guard let comments = post.comments else {
            XCTFail("Missing comments on post")
            return
        }
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier,
                                                 associatedField: "post"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertComment(comment, contains: post)
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(for: comment)!
        assertCommentDoesNotContainPost(queriedComment)
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await mutate(.create(post))
        queriedComment.post4CommentsPostId = savedPost.postId
        queriedComment.post4CommentsTitle = savedPost.title
        let saveCommentWithPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithPost)!
        assertComment(queriedComment2, contains: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        let queriedComment = try await query(for: comment)!
        assertComment(queriedComment, contains: post)
        let savedQueriedComment = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: savedQueriedComment)!
        assertComment(queriedComment2, contains: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(for: comment)!
        assertComment(queriedComment, contains: post)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await mutate(.create(newPost))
        queriedComment.post4CommentsPostId = newPost.postId
        queriedComment.post4CommentsTitle = newPost.title
        let saveCommentWithNewPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithNewPost)!
        assertComment(queriedComment2, contains: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(for: comment)!
        assertComment(queriedComment, contains: post)
        
        queriedComment.post4CommentsPostId = nil
        queriedComment.post4CommentsTitle = nil
        
        let saveCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)!
        assertCommentDoesNotContainPost(queriedCommentNoPost)
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        try await mutate(.delete(savedPost))
        
        // The expected behavior when deleting a post should be that the
        // child models are deleted (comment) followed by the parent model (post).
        try await assertModelDoesNotExist(savedPost)
        // Is there a way to delete the children models in uni directional relationships?
        try await assertModelExists(savedComment)
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
