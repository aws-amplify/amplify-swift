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

final class AWSDataStoreLazyLoadPostComment7Tests: AWSDataStoreLazyLoadBaseTest {

    func testLazyLoad() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(for: savedComment)
        try await assertComment(queriedComment, canLazyLoad: savedPost)
        let queriedPost = try await query(for: savedPost)
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
        
        // retrieve loaded model
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to retrieve the loaded post from the comment")
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
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier,
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
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithPost)
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: savedQueriedComment)
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithNewPost)
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)
        assertLazyModel(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment7Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        try await assertModelDoesNotExist(savedComment)
        try await assertModelDoesNotExist(savedPost)
    }
}

extension AWSDataStoreLazyLoadPostComment7Tests {
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
