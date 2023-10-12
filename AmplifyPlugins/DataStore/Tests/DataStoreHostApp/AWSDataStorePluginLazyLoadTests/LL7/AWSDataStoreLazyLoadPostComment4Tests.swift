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
        let savedPost = try await createAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: PostComment4Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: PostComment4Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let savedPost = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
        assertComment(savedComment, contains: savedPost)
        try await assertPost(savedPost, canLazyLoad: savedComment)
        
        // Assert on Queried Comment
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: savedPost)

        // Assert on Queried Post
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
        assertList(comments, state: .isNotLoaded(associatedIds: [post.postId, post.title],
                                                 associatedFields: ["post4CommentsPostId", "post4CommentsTitle"]))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertComment(comment, contains: post)
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment4Models())
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await createAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertCommentDoesNotContainPost(queriedComment)
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await createAndWaitForSync(post)
        queriedComment.post4CommentsPostId = savedPost.postId
        queriedComment.post4CommentsTitle = savedPost.title
        let saveCommentWithPost = try await updateAndWaitForSync(queriedComment)
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
        let savedPost = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let savedQueriedComment = try await updateAndWaitForSync(queriedComment)
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
        _ = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await createAndWaitForSync(newPost)
        queriedComment.post4CommentsPostId = newPost.postId
        queriedComment.post4CommentsTitle = newPost.title
        let saveCommentWithNewPost = try await updateAndWaitForSync(queriedComment)
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
        _ = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        
        queriedComment.post4CommentsPostId = nil
        queriedComment.post4CommentsTitle = nil
        
        let saveCommentRemovePost = try await updateAndWaitForSync(queriedComment)
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
        let savedPost = try await createAndWaitForSync(post)
        let savedComment = try await createAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        
        // The expected behavior when deleting a post should be that the
        // child models are deleted (comment) followed by the parent model (post).
        try await assertModelDoesNotExist(savedPost)
        // Is there a way to delete the children models in uni directional relationships?
        try await assertModelExists(savedComment)
    }
    
    func testObservePost() async throws {
        await setup(withModels: PostComment4Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let mutationEventReceived = expectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedPost = try? mutationEvent.decodeModel(as: Post.self),
                   receivedPost.postId == post.postId {
                    let savedComment = try await createAndWaitForSync(comment)
                    try await assertPost(receivedPost, canLazyLoad: savedComment)
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
        
        await fulfillment(of: [mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveComment() async throws {
        await setup(withModels: PostComment4Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await createAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let mutationEventReceived = expectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Comment.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedComment = try? mutationEvent.decodeModel(as: Comment.self),
                   receivedComment.commentId == comment.commentId {
                    assertComment(receivedComment, contains: savedPost)
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
        
        await fulfillment(of: [mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveQueryPost() async throws {
        await setup(withModels: PostComment4Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let snapshotReceived = expectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Post.self, where: Post.keys.postId == post.postId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedPost = querySnapshot.items.first {
                    let savedComment = try await createAndWaitForSync(comment)
                    try await assertPost(receivedPost, canLazyLoad: savedComment)
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
        
        await fulfillment(of: [snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
    
    func testObserveQueryComment() async throws {
        await setup(withModels: PostComment4Models())
        try await startAndWaitForReady()
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await createAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              post4CommentsPostId: post.postId,
                              post4CommentsTitle: post.title)
        let snapshotReceived = expectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Comment.self, where: Comment.keys.commentId == comment.commentId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedComment = querySnapshot.items.first {
                    assertComment(receivedComment, contains: savedPost)
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
        
        await fulfillment(of: [snapshotReceived], timeout: 60)
        querySnapshots.cancel()
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
