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
    
    func testEagerLoadVerbose() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        // The comment's post should be loaded, since `includes` include the post
        assertLazyModel(createdComment._post,
                        state: .loaded(model: createdPost))
        guard let loadedPost = try await createdComment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, post.id)
        
        // The loaded post should have comments that are not loaded
        guard let comments = loadedPost.comments else {
            XCTFail("Missing comments on post")
            return
        }
        assertList(comments, state: .isNotLoaded(associatedId: post.identifier,
                                                 associatedField: "post"))

        // load the comments
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
    
    func testLazyLoadVerbose() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let createdPost = try await mutate(.create(post))
        let createdComment = try await mutate(.create(comment))
        // The comment's post should not be loaded, since no `includes` is passed in.
        // And the codegenerated swift models have the new modelPath properties.
        assertLazyModel(createdComment._post,
                        state: .notLoaded(identifiers: ["id": createdPost.id]))
        
        // Since the comment is not loaded, load the post
        guard let loadedPost = try await createdComment.post else {
            XCTFail("Failed to retrieve the post from the comment")
            return
        }
        XCTAssertEqual(loadedPost.id, createdPost.id)
        // the loaded post should have comments
        guard let comments = loadedPost.comments else {
            XCTFail("Missing comments on post")
            return
        }
        // The loaded post should have comments that are also not loaded
        assertList(comments,
                   state: .isNotLoaded(associatedId: createdPost.id, associatedField: "post"))

        // load the comments
        try await comments.fetch()
        assertList(comments, state: .isLoaded(count: 1))
        guard let comment = comments.first else {
            XCTFail("Missing lazy loaded comment from post")
            return
        }
        
        // the loaded comment's post should not be loaded
        assertLazyModel(comment._post,
                        state: .notLoaded(identifiers: ["id": createdPost.id]))
    }
    
    
    // MARK: - WIP
    
    func testEagerLoad() async throws {
        await setup(withModels: PostComment4V2Models(), logLevel: .verbose)
        let post = Post(title: "title")
        let comment = Comment(content: "content", post: post)
        let savedPost = try await mutate(.create(post))
        let savedComment = try await mutate(.create(comment, includes: { comment in [comment.post]}))
        try await assertComment(savedComment, hasEagerLoaded: savedPost)
        
        let request = GraphQLRequest<Comment?>.get(Comment.self,
                                                   byId: savedComment.identifier,
                                                   includes: { comment in [comment.post]})
        let expectedDocument = """
        query GetComment4V2($id: ID!) {
          getComment4V2(id: $id) {
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
            }
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        let queriedComment = try await getQuery(request)
        XCTAssertNotNil(queriedComment)
        try await assertComment(queriedComment!, hasEagerLoaded: savedPost)
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
