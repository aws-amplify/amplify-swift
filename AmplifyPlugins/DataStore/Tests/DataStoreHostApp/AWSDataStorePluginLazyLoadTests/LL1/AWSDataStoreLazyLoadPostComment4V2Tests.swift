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

class AWSDataStoreLazyLoadPostComment4V2Tests: AWSDataStoreLazyLoadBaseTest {
    
    func testLazyLoad() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await queryComment(savedComment)
        try await assertComment(queriedComment, canLazyLoad: savedPost)
        let queriedPost = try await queryPost(savedPost)
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
        XCTAssertEqual(loadedPost.id, post.id)
        
        // retrieve loaded model
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to retrieve the loaded post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
        
        try await assertPost(loadedPost, canLazyLoad: comment)
    }
    
    func assertComment(_ comment: Comment,
                       canLazyLoad post: Post) async throws {
        assertLazyModel(comment._post,
                        state: .notLoaded(identifiers: ["id": post.identifier]))
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to load the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
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
        
        // further nested models should not be loaded
        assertLazyModel(comment._post,
                        state: .notLoaded(identifiers: ["id": post.identifier]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        let comment = Comment(content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await queryComment(savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await queryComment(saveCommentWithPost)
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await queryComment(savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: ["id": post.identifier]))
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await queryComment(savedQueriedComment)
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await queryComment(savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: ["id": post.identifier]))
        
        let newPost = Post(title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await queryComment(saveCommentWithNewPost)
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await queryComment(savedComment)
        assertLazyModel(queriedComment._post,
                        state: .notLoaded(identifiers: ["id": post.identifier]))
        
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await queryComment(saveCommentRemovePost)
        assertLazyModel(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose, eagerLoad: false)
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        try await assertModelDoesNotExist(savedComment)
        try await assertModelDoesNotExist(savedPost)
    }
}

extension AWSDataStoreLazyLoadPostComment4V2Tests {
    typealias Post = Post4V2
    typealias Comment = Comment4V2
    
    struct PostComment4V2Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post4V2.self)
            ModelRegistry.register(modelType: Comment4V2.self)
        }
    }
    
    func queryComment(_ comment: Comment) async throws -> Comment {
        guard let queriedComment = try await Amplify.DataStore.query(Comment.self,
                                                                     byIdentifier: comment.id) else {
            XCTFail("Failed to query comment")
            throw "Failed to query comment"
        }
        return queriedComment
    }
    
    func queryPost(_ post: Post) async throws -> Post {
        guard let queriedPost = try await Amplify.DataStore.query(Post.self,
                                                                  byIdentifier: post.id) else {
            XCTFail("Failed to query post")
            throw "Failed to query post"
        }
        return queriedPost
    }
}
