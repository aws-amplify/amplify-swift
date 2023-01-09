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

final class GraphQLLazyLoadPostComment8Tests: GraphQLLazyLoadBaseTest {

    func testSave() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
    }
    
    func testQueryThenLazyLoad() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        assertComment(savedComment, contains: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId, content: comment.content)))!
        assertComment(queriedComment, contains: savedPost)
        let queriedPost = try await query(.get(Post.self, byIdentifier: .identifier(postId: post.postId, title: post.title)))!
        try await assertPost(queriedPost, canLazyLoad: savedComment)
    }
    
    func assertComment(_ comment: Comment, contains post: Post) {
        XCTAssertEqual(comment.postId, post.postId)
        XCTAssertEqual(comment.postTitle, post.title)
    }
    
    func assertCommentDoesNotContainPost(_ comment: Comment) {
        XCTAssertNil(comment.postId)
        XCTAssertNil(comment.postTitle)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad comment: Comment) async throws {
        guard let comments = post.comments else {
            XCTFail("Missing comments on post")
            return
        }
        assertList(comments, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title],
                                                 associatedField: "postId"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertComment(comment, contains: post)
    }
    
    /*
     This test fails when the create mutation contains Null values for the foreign keys. On create mutation, we should
     be able to detect that the values being set are foreign key fields and remove them from the input
     {
       "variables" : {
         "input" : {
           "content" : "content",
           "postId" : null,
           "commentId" : "532C8869-FD00-4694-A2DE-38223E080206",
           "postTitle" : null
         }
       },
       "query" : "mutation CreateComment8($input: CreateComment8Input!) {\n  createComment8(input: $input) {\n    commentId\n    content\n    createdAt\n    postId\n    postTitle\n    updatedAt\n    __typename\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"
     }
     */
    func testSaveWithoutPost() async throws {
        throw XCTSkip("Create mutation with null foreign keys fail.")
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await mutate(.create(comment))
//        var queriedComment = try await query(.get(Comment.self, byId: comment.commentId))!
//        assertCommentDoesNotContainPost(queriedComment)
//        let post = Post(postId: UUID().uuidString, title: "title")
//        let savedPost = try await mutate(.create(post))
//        queriedComment.postId = savedPost.postId
//        queriedComment.postTitle = savedPost.title
//        let saveCommentWithPost = try await mutate(.update(queriedComment))
//        let queriedComment2 = try await query(for: saveCommentWithPost)!
//        assertComment(queriedComment2, contains: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        let queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId, content: comment.content)))!
        assertComment(queriedComment, contains: post)
        let savedQueriedComment = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: savedQueriedComment)!
        assertComment(queriedComment2, contains: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId, content: comment.content)))!
        assertComment(queriedComment, contains: post)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await mutate(.create(newPost))
        queriedComment.postId = newPost.postId
        queriedComment.postTitle = newPost.title
        let saveCommentWithNewPost = try await mutate(.update(queriedComment))
        let queriedComment2 = try await query(for: saveCommentWithNewPost)!
        assertComment(queriedComment2, contains: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        _ = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byIdentifier: .identifier(commentId: comment.commentId, content: comment.content)))!
        assertComment(queriedComment, contains: post)
        
        queriedComment.postId = nil
        queriedComment.postTitle = nil
        
        let saveCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)!
        assertCommentDoesNotContainPost(queriedCommentNoPost)
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment8Models(), logLevel: .verbose)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment))
        
        try await mutate(.delete(savedPost))
        try await assertModelDoesNotExist(savedPost)
        try await assertModelExists(savedComment)
        try await mutate(.delete(savedComment))
        try await assertModelDoesNotExist(savedComment)
    }
}

extension GraphQLLazyLoadPostComment8Tests: DefaultLogger { }

extension GraphQLLazyLoadPostComment8Tests {
    typealias Post = Post8
    typealias Comment = Comment8
    
    struct PostComment8Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post8.self)
            ModelRegistry.register(modelType: Comment8.self)
        }
    }
}
