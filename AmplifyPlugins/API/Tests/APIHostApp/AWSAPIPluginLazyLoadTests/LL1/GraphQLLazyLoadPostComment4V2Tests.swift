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
        let createdPost = try await mutate(.create(post))
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
}

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
