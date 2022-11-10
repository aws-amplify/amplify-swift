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

final class GraphQLLazyLoadPostComment4V2Tests: GraphQLLazyLoadBaseTest {

    func testSetup() async throws {
        await setup(withModels: PostComment4V2Models())
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post should be lazy loaded
    func testCommentWithLazyLoadPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment))
        // The comment's post should not be loaded, since no `includes` is passed in.
        // And the codegenerated swift models have the new modelPath properties.
        assertLazyModel(createdComment._post, state: .notLoaded(identifiers: ["id": createdPost.id]))
        let loadedPost = try await createdComment.post!
        XCTAssertEqual(loadedPost.id, createdPost.id)
        let comments = loadedPost.comments!
        // The loaded post should have comments that are also not loaded
        assertList(comments, state: .isNotLoaded(associatedId: createdPost.id, associatedField: "post"))
        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        // the loaded comment's post should not be loaded
        assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["id": createdPost.id]))
    }
    
    // With `includes` on `comment.post`, the comment's post should be eager loaded.
    func testCommentWithEagerLoadPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        // The comment's post should be loaded, since `includes` include the post
        assertLazyModel(createdComment._post, state: .loaded(model: createdPost))
        let loadedPost = try await createdComment.post!
        XCTAssertEqual(loadedPost.id, post.id)
        // The loaded post should have comments that are not loaded
        let comments = loadedPost.comments!
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier, associatedField: "post"))
        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        // further nested models should not be loaded
        assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["id": post.identifier]))
    }
    
    // With `includes` on `comment.post.comments`,
    func testCommentWithEagerLoadPostAndPostComments() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let request = GraphQLRequest<Comment>.create(comment, includes: { comment in [comment.post.comments]})
        let expectedDocument = """
        mutation CreateComment4V2($input: CreateComment4V2Input!) {
          createComment4V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              __typename
              createdAt
              title
              updatedAt
              comments {
                items {
                  id
                  content
                  createdAt
                  updatedAt
                  post {
                    id
                    __typename
                  }
                  __typename
                }
              }
            }
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        let createdComment = try await mutate(request)
        assertLazyModel(createdComment._post, state: .loaded(model: createdPost))
        let loadedPost = try await createdComment.post!
        // The loaded post should have comments that are also loaded, since `includes` include the `post.comments`
        let comments = loadedPost.comments!
        assertList(comments, state: .isLoaded(count: 1))
        // further nested models should not be loaded
        assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["id": post.identifier]))
    }
    
    // This looks broken
    func testCommentWithEagerLoadPostAndPostCommentsAndPostCommentsPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        let request = GraphQLRequest<Comment>.create(comment, includes: { comment in [comment.post.comments.post]})
        let expectedDocument = """
        mutation CreateComment4V2($input: CreateComment4V2Input!) {
          createComment4V2(input: $input) {
            id
            content
            createdAt
            updatedAt
            post {
              id
              __typename
              createdAt
              title
              updatedAt
              comments {
                items {
                  id
                  content
                  createdAt
                  updatedAt
                  post {
                    id
                    __typename
                  }
                  __typename
                }
              }
              post {
                id
                createdAt
                title
                updatedAt
                __typename
              }
            }
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        let createdComment = try await mutate(request)
    }
    
    // Without `includes` and latest codegenerated types with the model path, the post's comments should be lazy loaded
    func testPostWithLazyLoadComments() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        let queriedPost = try await query(.get(Post.self, byId: post.id))!
        let comments = queriedPost.comments!
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier, associatedField: "post"))
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["id": post.identifier]))
    }
    
    // With `includes` on `post.comments` should eager load the post's comments
    func testPostWithEagerLoadComments() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        _ = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        let queriedPost = try await query(.get(Post.self, byId: post.id, includes: { post in [post.comments]}))!
        let comments = queriedPost.comments!
        assertList(comments, state: .isLoaded(count: 1))
        assertLazyModel(comments.first!._post, state: .notLoaded(identifiers: ["id": post.identifier]))
    }
    
    // With `includes` on `post.comments.post` should eager load the post's comments' post
    func testPostWithEagerLoadCommentsAndPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        _ = try await mutate(.create(comment))
        let queriedPost = try await query(.get(Post.self, byId: post.id, includes: { post in [post.comments.post]}))!
        let comments = queriedPost.comments!
        assertList(comments, state: .isLoaded(count: 1))
        assertLazyModel(comments.first!._post, state: .loaded(model: createdPost))
    }
    
    func testCreateWithoutPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let comment = Comment(content: "content")
        try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.id))!
        assertLazyModel(queriedComment._post, state: .notLoaded(identifiers: nil))
        let post = Post(title: "title")
        let createdPost = try await mutate(.create(post))
        queriedComment.setPost(createdPost)
        let updateCommentWithPost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(.get(Comment.self, byId: updateCommentWithPost.id))!
        assertLazyModel(queriedCommentAfterUpdate._post, state: .notLoaded(identifiers: ["id": post.id]))
        let queriedCommentWithPost = try await query(.get(Comment.self, byId: queriedCommentAfterUpdate.id, includes: { comment in [comment.post]}))!
        assertLazyModel(queriedCommentWithPost._post, state: .loaded(model: createdPost))
    }
    
    func testUpdateToNewPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.id))!
        assertLazyModel(queriedComment._post, state: .notLoaded(identifiers: ["id": post.id]))
        
        let newPost = Post(title: "title")
        let createdNewPost = try await mutate(.create(newPost))
        queriedComment.setPost(newPost)
        let updateCommentWithPost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(.get(Comment.self, byId: updateCommentWithPost.id))!
        assertLazyModel(queriedCommentAfterUpdate._post, state: .notLoaded(identifiers: ["id": newPost.id]))
        let queriedCommentWithPost = try await query(.get(Comment.self, byId: queriedCommentAfterUpdate.id, includes: { comment in [comment.post]}))!
        assertLazyModel(queriedCommentWithPost._post, state: .loaded(model: createdNewPost))
    }
    
    func testUpdateRemovePost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(post))
        try await mutate(.create(comment))
        var queriedComment = try await query(.get(Comment.self, byId: comment.id))!
        assertLazyModel(queriedComment._post, state: .notLoaded(identifiers: ["id": post.id]))
        
        queriedComment.setPost(nil)
        let updateCommentRemovePost = try await mutate(.update(queriedComment))
        let queriedCommentAfterUpdate = try await query(.get(Comment.self, byId: updateCommentRemovePost.id))!
        assertLazyModel(queriedCommentAfterUpdate._post, state: .notLoaded(identifiers: nil))
    }
    
    func testDelete() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        try await mutate(.create(comment))
            
        try await mutate(.delete(createdPost))
        let queriedPost = try await query(.get(Post.self, byId: post.id))
        XCTAssertNil(queriedPost)
        let queriedComment = try await query(.get(Comment.self, byId: comment.id))!
        assertLazyModel(queriedComment._post, state: .notLoaded(identifiers: nil))
        try await mutate(.delete(queriedComment))
        let queryDeletedComment = try await query(.get(Comment.self, byId: comment.id))
        XCTAssertNil(queryDeletedComment)
    }
    
    func testSubscribeToComments() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        try await mutate(.create(post))
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedComment = asyncExpectation(description: "onCreatedComment received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Comment.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdComment):
                            log.verbose("Successfully got createdComment from subscription: \(createdComment)")
                            assertLazyModel(createdComment._post, state: .notLoaded(identifiers: ["id": post.id]))
                            await onCreatedComment.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(comment))
        await waitForExpectations([onCreatedComment], timeout: 10)
        subscription.cancel()
    }
    
    // The identical `includes` parameter should be used because the selection set of the mutation
    // has to match the selection set of the subscription.
    func testSubscribeToCommentsIncludesPost() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        try await mutate(.create(post))
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedComment = asyncExpectation(description: "onCreatedComment received")
        let subscriptionIncludes = Amplify.API.subscribe(request: .subscription(of: Comment.self,
                                                                                type: .onCreate,
                                                                                includes: { comment in [comment.post]}))
        Task {
            do {
                for try await subscriptionEvent in subscriptionIncludes {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdComment):
                            log.verbose("Successfully got createdComment from subscription: \(createdComment)")
                            assertLazyModel(createdComment._post, state: .loaded(model: post))
                            await onCreatedComment.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 20)
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(comment, includes: { comment in [comment.post] }))
        await waitForExpectations([onCreatedComment], timeout: 20)
        subscriptionIncludes.cancel()
    }
    
    func testSubscribeToPosts() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedPost = asyncExpectation(description: "onCreatedPost received")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdPost):
                            log.verbose("Successfully got createdPost from subscription: \(createdPost)")
                            assertList(createdPost.comments!, state: .isNotLoaded(associatedId: post.identifier, associatedField: "post"))
                            await onCreatedPost.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(post))
        await waitForExpectations([onCreatedPost], timeout: 10)
        subscription.cancel()
    }
    
    func testSubscribeToPostsIncludes() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        
        let connected = asyncExpectation(description: "subscription connected")
        let onCreatedPost = asyncExpectation(description: "onCreatedPost received")
        let subscriptionIncludes = Amplify.API.subscribe(request: .subscription(of: Post.self,
                                                                                type: .onCreate,
                                                                                includes: { post in [post.comments]}))
        Task {
            do {
                for try await subscriptionEvent in subscriptionIncludes {
                    switch subscriptionEvent {
                    case .connection(let subscriptionConnectionState):
                        log.verbose("Subscription connect state is \(subscriptionConnectionState)")
                        if case .connected = subscriptionConnectionState {
                            await connected.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let createdPost):
                            log.verbose("Successfully got createdPost from subscription: \(createdPost)")
                            assertList(createdPost.comments!, state: .isLoaded(count: 0))
                            await onCreatedPost.fulfill()
                        case .failure(let error):
                            XCTFail("Got failed result with \(error.errorDescription)")
                        }
                    }
                }
            } catch {
                XCTFail("Subscription has terminated with \(error)")
            }
        }
        
        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(post, includes: { post in [post.comments]}))
        await waitForExpectations([onCreatedPost], timeout: 10)
        subscriptionIncludes.cancel()
    }
}

extension GraphQLLazyLoadPostComment4V2Tests: DefaultLogger { }

extension GraphQLLazyLoadBaseTest {
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
