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

final class AWSDataStoreLazyLoadPostCommentWithCompositeKeyTests: AWSDataStoreLazyLoadBaseTest {

    func testLazyLoad() async throws {
        await setup(withModels: PostCommentWithCompositeKeyModels(), logLevel: .verbose, eagerLoad: false)
        
        let post = PostWithCompositeKey(title: "title")
        let comment = CommentWithCompositeKey(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)

        guard let queriedComment = try await Amplify.DataStore.query(CommentWithCompositeKey.self,
                                                                     byIdentifier: .identifier(
                                                                        id: savedComment.id,
                                                                        content: savedComment.content)) else {
            XCTFail("Failed to query comment")
            return
        }
        try await assertComment(queriedComment, canLazyLoad: savedPost)

        guard let queriedPost = try await Amplify.DataStore.query(PostWithCompositeKey.self,
                                                                  byIdentifier: .identifier(
                                                                    id: savedPost.id,
                                                                    title: savedPost.title)) else {
            XCTFail("Failed to query post")
            return
        }
        try await assertPost(queriedPost, canLazyLoad: savedComment)
    }
    
    func assertComment(_ comment: CommentWithCompositeKey,
                       hasEagerLoaded post: PostWithCompositeKey) async throws {
        // assert that it is loaded
        switch comment._post.modelProvider.getState() {
        case .notLoaded:
            XCTFail("Saving a comment should eager load the post")
        case .loaded(let loadedPost):
            XCTAssertEqual(loadedPost?.id, post.id)
        }
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
    
    func assertComment(_ comment: CommentWithCompositeKey,
                       canLazyLoad post: PostWithCompositeKey) async throws {
        // assert that it is not loaded
        switch comment._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            guard let identifier = identifiers.first else {
                XCTFail("missing identifiers")
                return
            }
            XCTAssertEqual(identifier.key, "@@primaryKey")
            XCTAssertEqual(identifier.value, post.identifier)
        case .loaded:
            XCTFail("Should not be loaded")
        }
        
        // lazy load
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to retrieve the loaded post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
        
        try await assertPost(loadedPost, canLazyLoad: comment)
    }
    
    func assertPost(_ post: PostWithCompositeKey,
                    canLazyLoad comment: CommentWithCompositeKey) async throws {
        guard let comments = post.comments else {
            XCTFail("Missing comments on post")
            return
        }
        
        // assert that it is not loaded
        switch comments.listProvider.getState() {
        case .notLoaded(let associatedId, let associatedField):
            XCTAssertEqual(associatedId, post.identifier)
            XCTAssertEqual(associatedField, "post")
        case .loaded:
            XCTFail("It should not be loaded")
        }
        
        // lazy load
        try await comments.fetch()
        switch comments.listProvider.getState() {
        case .notLoaded:
            XCTFail("It should be loaded after calling `fetch`")
        case .loaded(let loadedComments):
            XCTAssertEqual(loadedComments.count, 1)
        }
        
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        
        // further nested models should not be loaded
        switch comment._post.modelProvider.getState() {
        case .notLoaded(let identifiers):
            guard let identifier = identifiers.first else {
                XCTFail("missing identifiers")
                return
            }
            XCTAssertEqual(identifier.key, "@@primaryKey")
            XCTAssertEqual(identifier.value, post.identifier)
        case .loaded:
            XCTFail("Should be not loaded")
        }
    }
    
    func testDelete() async throws {
        await setup(withModels: PostCommentWithCompositeKeyModels(), logLevel: .verbose, eagerLoad: false)
        
        let post = PostWithCompositeKey(title: "title")
        let comment = CommentWithCompositeKey(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        
        let queriedComment = try await Amplify.DataStore.query(CommentWithCompositeKey.self,
                                                               byIdentifier: .identifier(
                                                                id: savedComment.id,
                                                                content: savedComment.content))
        XCTAssertNil(queriedComment)
        let commentMetadataIdentifier = MutationSyncMetadata.identifier(modelName: CommentWithCompositeKey.modelName,
                                                                        modelId: comment.identifier)
        guard let commentMetadata = try await Amplify.DataStore.query(MutationSyncMetadata.self,
                                                                      byId: commentMetadataIdentifier) else {
            XCTFail("Could not retrieve metadata for comment")
            return
        }
        XCTAssertTrue(commentMetadata.deleted)
        
        let queriedPost = try await Amplify.DataStore.query(PostWithCompositeKey.self,
                                                            byIdentifier: .identifier(
                                                                id: savedPost.id,
                                                                title: savedPost.title))
        XCTAssertNil(queriedPost)
        let postMetadataIdentifier = MutationSyncMetadata.identifier(modelName: PostWithCompositeKey.modelName,
                                                                        modelId: post.identifier)
        guard let postMetadata = try await Amplify.DataStore.query(MutationSyncMetadata.self,
                                                                      byId: postMetadataIdentifier) else {
            XCTFail("Could not retrieve metadata for post")
            return
        }
        XCTAssertTrue(postMetadata.deleted)
    }
}

extension AWSDataStoreLazyLoadPostCommentWithCompositeKeyTests {
    struct PostCommentWithCompositeKeyModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
        }
    }
}
