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
    
    func testStart() async throws {
        await setup(withModels: PostComment4V2Models())
        try await startAndWaitForReady()
        printDBPath()
    }
    
    func testSavePost() async throws {
        await setup(withModels: PostComment4V2Models())
        let post = Post(title: "title")
        let savedPost = try await saveAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: PostComment4V2Models())
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: PostComment4V2Models())
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
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
        assertLazyReference(comment._post,
                            state: .loaded(model: post))
        
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
        
        try await assertPost(loadedPost, canLazyLoad: comment)
    }
    
    func assertComment(_ comment: Comment,
                       canLazyLoad post: Post) async throws {
        assertLazyReference(comment._post,
                        state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
        guard let loadedPost = try await comment.post else {
            XCTFail("Failed to load the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
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
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier,
                                                 associatedField: "post"))
        
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        
        // further nested models should not be loaded
        assertLazyReference(comment._post,
                        state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment4V2Models())
        let comment = Comment(content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithPost)
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment4V2Models())
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: savedQueriedComment)
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4V2Models())
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
        
        let newPost = Post(title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithNewPost)
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4V2Models())
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [.init(name: "id", value: post.identifier)]))
        
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)
        assertLazyReference(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4V2Models())
        
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        try await assertModelDoesNotExist(savedComment)
        try await assertModelDoesNotExist(savedPost)
    }
    
    func testObservePost() async throws {
        await setup(withModels: PostComment4V2Models())
        try await startAndWaitForReady()
        let post = Post(title: "title")
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version, version == 1 {
                    do {
                        let receivedPost = try mutationEvent.decodeModel(as: Post.self)
                        if receivedPost.id == post.id {
                            await mutationEventReceived.fulfill()
                        }
                    } catch {
                    }
                }
                
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        do {
            let response = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveComment() async throws {
        await setup(withModels: PostComment4V2Models())
        try await startAndWaitForReady()
        let post = Post(title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        let comment = Comment(content: "content", post: post)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Comment.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version, version == 1 {
                    do {
                        let receivedComment = try mutationEvent.decodeModel(as: Comment.self)
                        if receivedComment.id == comment.id {
                            await mutationEventReceived.fulfill()
                        }
                    } catch {
                    }
                }
                
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        do {
            let response = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
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
}
