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

final class AWSDataStoreLazyLoadPostComment4Tests: AWSDataStoreLazyLoadBaseTest {

    func testSavePost() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
    }
    
    func testLazyLoad() async throws {
        throw XCTSkip("Need further investigation, saved post cannot lazy load comment")
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        assertComment(savedComment, contains: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: savedPost)
        let queriedPost = try await query(for: savedPost)
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
    
    /*
     This test fails when the create mutation contains Null values for the foreign keys. On create mutation, we should
     be able to detect that the values being set are foreign key fields and remove them from the input
     {
       "variables" : {
         "input" : {
           "post4CommentsPostId" : null,
           "post4CommentsTitle" : null,
           "commentId" : "A3C577B3-7CAD-4603-947A-FB1EBEC0E8CE",
           "content" : "content"
         }
       },
       "query" : "mutation CreateComment4($input: CreateComment4Input!) {\n  createComment4(input: $input) {\n    commentId\n    content\n    createdAt\n    post4CommentsPostId\n    post4CommentsTitle\n    updatedAt\n    __typename\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"
     }
     One or more parameter values were invalid: Type mismatch for Index Key post4CommentsPostId Expected: S Actual: NULL IndexName: gsi-Post4.comments
     */
    func testSaveWithoutPost() async throws {
        throw XCTSkip("Need further investigation")
        await setup(withModels: PostComment4Models())
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertCommentDoesNotContainPost(queriedComment)
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.post4CommentsPostId = savedPost.postId
        queriedComment.post4CommentsTitle = savedPost.title
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithPost)
        assertComment(queriedComment2, contains: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: savedQueriedComment)
        assertComment(queriedComment2, contains: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.post4CommentsPostId = newPost.postId
        queriedComment.post4CommentsTitle = newPost.title
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithNewPost)
        assertComment(queriedComment2, contains: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        
        queriedComment.post4CommentsPostId = nil
        queriedComment.post4CommentsTitle = nil
        
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)
        assertCommentDoesNotContainPost(queriedCommentNoPost)
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        
        // The expected behavior when deleting a post should be that the
        // child models are deleted (comment) followed by the parent model (post).
        try await assertModelDoesNotExist(savedPost)
        // Is there a way to delete the children models in uni directional relationships?
        try await assertModelExists(savedComment)
    }
}

extension AWSDataStoreLazyLoadPostComment4Tests {
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
