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

    func testSavePost() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        try await saveAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: PostComment7Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await assertComment(savedComment, canLazyLoad: savedPost)
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
        assertLazyReference(comment._post,
                            state: .notLoaded(identifiers: [
                                .init(name: Post7.keys.postId.stringValue, value: post.postId),
                                .init(name: Post7.keys.title.stringValue, value: post.title)
                            ]))
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
        assertList(comments, state: .isNotLoaded(associatedIds: [post.identifier],
                                                 associatedFields: ["post"]))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertLazyReference(comment._post,
                        state: .notLoaded(identifiers: [
                            .init(name: Post7.keys.postId.stringValue, value: post.postId),
                            .init(name: Post7.keys.title.stringValue, value: post.title)
                        ]))
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment7Models())
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: nil))
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.setPost(savedPost)
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithPost)
        try await assertComment(queriedComment2, canLazyLoad: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment7Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [
                            .init(name: Post.keys.postId.stringValue, value: post.postId),
                            .init(name: Post.keys.title.stringValue, value: post.title)
                        ]))
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: savedQueriedComment)
        try await assertComment(queriedComment2, canLazyLoad: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [
                            .init(name: Post.keys.postId.stringValue, value: post.postId),
                            .init(name: Post.keys.title.stringValue, value: post.title)
                        ]))
        
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.setPost(newPost)
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithNewPost)
        try await assertComment(queriedComment2, canLazyLoad: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertLazyReference(queriedComment._post,
                        state: .notLoaded(identifiers: [
                            .init(name: Post.keys.postId.stringValue, value: post.postId),
                            .init(name: Post.keys.title.stringValue, value: post.title)
                        ]))
        
        queriedComment.setPost(nil)
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)
        assertLazyReference(queriedCommentNoPost._post,
                        state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment7Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        try await assertModelDoesNotExist(savedComment)
        try await assertModelDoesNotExist(savedPost)
    }
    
    func testObservePost() async throws {
        await setup(withModels: PostComment7Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedPost = try? mutationEvent.decodeModel(as: Post.self),
                   receivedPost.postId == post.postId {
                        
                    try await saveAndWaitForSync(comment)
                    guard let comments = receivedPost.comments else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await comments.fetch()
                    } catch {
                        XCTFail("Failed to lazy load comments \(error)")
                    }
                    XCTAssertEqual(comments.count, 1)
                    
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveComment() async throws {
        await setup(withModels: PostComment7Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Comment.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedComment = try? mutationEvent.decodeModel(as: Comment.self),
                   receivedComment.commentId == comment.commentId {
                    try await assertComment(receivedComment, canLazyLoad: savedPost)
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveQueryPost() async throws {
        await setup(withModels: PostComment7Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Post.self, where: Post.keys.postId == post.postId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedPost = querySnapshot.items.first {
                    try await saveAndWaitForSync(comment)
                    guard let comments = receivedPost.comments else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await comments.fetch()
                    } catch {
                        XCTFail("Failed to lazy load comments \(error)")
                    }
                    XCTAssertEqual(comments.count, 1)
                    
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: post, modelSchema: Post.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
    
    func testObserveQueryComment() async throws {
        await setup(withModels: PostComment7Models())
        try await startAndWaitForReady()
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString, content: "content", post: post)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Comment.self, where: Comment.keys.commentId == comment.commentId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedComment = querySnapshot.items.first {
                    try await assertComment(receivedComment, canLazyLoad: savedPost)
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: comment, modelSchema: Comment.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
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
