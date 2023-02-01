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

final class AWSDataStoreLazyLoadPostComment8Tests: AWSDataStoreLazyLoadBaseTest {

    func testSavePost() async throws {
        await setup(withModels: PostComment8Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
    }
    
    func testSaveComment() async throws {
        await setup(withModels: PostComment8Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
    }
    
    func testLazyLoad() async throws {
        throw XCTSkip("Need further investigation, saved post cannot lazy load comment")
        await setup(withModels: PostComment8Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        assertComment(savedComment, contains: savedPost)
        // TODO: problem here
        try await assertPost(savedPost, canLazyLoad: savedComment)
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: savedPost)
        let queriedPost = try await query(for: savedPost)
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
        // This is a bit off, the post.identifier is the CPK while the associated field is just "postId",
        // Loading the comments by the post identifier should be
        // "query all comments where the predicate is field("@@postForeignKey") == "[postId]#[title]"
        // List fetching is broken for this use case "uni directional has-many"
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier,
                                                 associatedField: "postId"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        assertComment(comment, contains: post)
    }
    
    func testSaveWithoutPost() async throws {
        await setup(withModels: PostComment8Models())
        let comment = Comment(commentId: UUID().uuidString, content: "content")
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertCommentDoesNotContainPost(queriedComment)
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        queriedComment.postId = savedPost.postId
        queriedComment.postTitle = savedPost.title
        let saveCommentWithPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithPost)
        assertComment(queriedComment2, contains: post)
    }
    
    func testUpdateFromQueriedComment() async throws {
        await setup(withModels: PostComment8Models())
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        let queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let savedQueriedComment = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: savedQueriedComment)
        assertComment(queriedComment2, contains: savedPost)
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment8Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedComment.postId = newPost.postId
        queriedComment.postTitle = newPost.title
        let saveCommentWithNewPost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedComment2 = try await query(for: saveCommentWithNewPost)
        assertComment(queriedComment2, contains: newPost)
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment8Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        _ = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        var queriedComment = try await query(for: savedComment)
        assertComment(queriedComment, contains: post)
        
        queriedComment.postId = nil
        queriedComment.postTitle = nil
        
        let saveCommentRemovePost = try await saveAndWaitForSync(queriedComment, assertVersion: 2)
        let queriedCommentNoPost = try await query(for: saveCommentRemovePost)
        assertCommentDoesNotContainPost(queriedCommentNoPost)
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment8Models())
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let savedPost = try await saveAndWaitForSync(post)
        let savedComment = try await saveAndWaitForSync(comment)
        try await deleteAndWaitForSync(savedPost)
        
        // The expected behavior when deleting a post should be that the
        // child models are deleted (comment) followed by the parent model (post).
        try await assertModelDoesNotExist(savedPost)
        // Is there a way to delete the children models in uni directional relationships?
        try await assertModelExists(savedComment)
    }
    
    func testObservePost() async throws {
        await setup(withModels: PostComment8Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedPost = try? mutationEvent.decodeModel(as: Post.self),
                   receivedPost.postId == post.postId {
                      
                    // TODO: Needs further investigation, saved post cannot lazy load comment
                    //let savedComment = try await saveAndWaitForSync(comment)
                    //try await assertPost(receivedPost, canLazyLoad: savedComment)
                    
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
        await setup(withModels: PostComment8Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
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
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveQueryPost() async throws {
        await setup(withModels: PostComment8Models())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Post.self, where: Post.keys.postId == post.postId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedPost = querySnapshot.items.first {
                    // TODO: Needs further investigation, saved post cannot lazy load comment
                    //let savedComment = try await saveAndWaitForSync(comment)
                    //try await assertPost(receivedPost, canLazyLoad: savedComment)
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
        await setup(withModels: PostComment8Models())
        try await startAndWaitForReady()
        
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await saveAndWaitForSync(post)
        let comment = Comment(commentId: UUID().uuidString,
                              content: "content",
                              postId: post.postId,
                              postTitle: post.title)
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
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
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
}

extension AWSDataStoreLazyLoadPostComment8Tests {
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
