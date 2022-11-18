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

final class GraphQLLazyLoadBlogPostComment8V2Tests: GraphQLLazyLoadBaseTest {

    func testSaveBlog() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let blog = Blog(name: "name")
        let createdBlog = try await mutate(.create(blog))
        let queriedBlog = try await query(for: createdBlog)!
        assertList(queriedBlog.posts!, state: .isNotLoaded(associatedIdentifiers: [blog.id], associatedField: "blog"))
        try await queriedBlog.posts?.fetch()
        assertList(queriedBlog.posts!, state: .isLoaded(count: 0))
    }
    
    func testSavePost() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let post = Post(name: "name", randomId: "randomId")
        let createdPost = try await mutate(.create(post))
        let queriedPost = try await query(for: createdPost)!
        assertList(queriedPost.comments!, state: .isNotLoaded(associatedIdentifiers: [post.id], associatedField: "post"))
        try await queriedPost.comments?.fetch()
        assertList(queriedPost.comments!, state: .isLoaded(count: 0))
        
        assertLazyReference(queriedPost._blog, state: .notLoaded(identifiers: nil))
    }
    
    func testSaveBlogThenPost() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let blog = Blog(name: "name")
        let createdBlog = try await mutate(.create(blog))
        let post = Post(name: "name", randomId: "randomId", blog: blog)
        let createdPost = try await mutate(.create(post))
        
        // the blog can load the posts
        assertList(createdBlog.posts!, state: .isNotLoaded(associatedIdentifiers: [blog.id], associatedField: "blog"))
        try await createdBlog.posts?.fetch()
        assertList(createdBlog.posts!, state: .isLoaded(count: 1))
        assertLazyReference(createdBlog.posts!.first!._blog, state: .notLoaded(identifiers: [.init(name: "id", value: blog.id)]))
        
        // the post can load the blog
        assertLazyReference(createdPost._blog, state: .notLoaded(identifiers: [.init(name: "id", value: blog.id)]))
        let loadedBlog = try await createdPost.blog!
        assertLazyReference(createdPost._blog, state: .loaded(model: loadedBlog))
        assertList(loadedBlog.posts!, state: .isNotLoaded(associatedIdentifiers: [blog.id], associatedField: "blog"))
    }
    
    func testSaveComment() async throws {
        await setup(withModels: BlogPostComment8V2Models())
        let comment = Comment(content: "content")
        let createdComment = try await mutate(.create(comment))
        assertLazyReference(createdComment._post, state: .notLoaded(identifiers: nil))
    }
    
    func testSavePostComment() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let post = Post(name: "name", randomId: "randomId")
        let createdPost = try await mutate(.create(post))
        let comment = Comment(content: "content", post: post)
        let createdComment = try await mutate(.create(comment))
        
        // the comment can load the post
        assertLazyReference(createdComment._post, state: .notLoaded(identifiers: [.init(name: "id", value: post.id)]))
        let loadedPost = try await createdComment.post!
        assertList(loadedPost.comments!, state: .isNotLoaded(associatedIdentifiers: [post.id], associatedField: "post"))
        
        // the post can load the comment
        assertList(createdPost.comments!, state: .isNotLoaded(associatedIdentifiers: [post.id], associatedField: "post"))
        try await createdPost.comments?.fetch()
        assertList(createdPost.comments!, state: .isLoaded(count: 1))
    }
    
    func testSaveBlogPostComment() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let blog = Blog(name: "name")
        let createdBlog = try await mutate(.create(blog))
        let post = Post(name: "name", randomId: "randomId", blog: blog)
        try await mutate(.create(post))
        let comment = Comment(content: "content", post: post)
        let createdComment = try await mutate(.create(comment))
        
        // the comment can load the post and load the blog
        assertLazyReference(createdComment._post, state: .notLoaded(identifiers: [.init(name: "id", value: post.id)]))
        let loadedPost = try await createdComment.post!
        assertLazyReference(loadedPost._blog, state: .notLoaded(identifiers: [.init(name: "id", value: blog.id)]))
        let loadedBlog = try await loadedPost.blog!
        assertList(loadedBlog.posts!, state: .isNotLoaded(associatedIdentifiers: [blog.id], associatedField: "blog"))
        
        // the blog can load the post and load the comment
        assertList(createdBlog.posts!, state: .isNotLoaded(associatedIdentifiers: [createdBlog.id], associatedField: "blog"))
        try await createdBlog.posts?.fetch()
        let loadedPost2 = createdBlog.posts!.first!
        assertList(loadedPost2.comments!, state: .isNotLoaded(associatedIdentifiers: [loadedPost2.id], associatedField: "post"))
        try await loadedPost2.comments?.fetch()
        assertLazyReference(loadedPost2.comments!.first!._post, state: .notLoaded(identifiers: [.init(name: "id", value: post.id)]))
    }
    
    func testBlogIncludesPostAndPostIncludesBlog() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let blog = Blog(name: "name")
        try await mutate(.create(blog))
        let post = Post(name: "name", randomId: "randomId", blog: blog)
        try await mutate(.create(post))
        
        // blog includes post
        let queriedBlogWithPost = try await query(.get(Blog.self,
                                                       byIdentifier: blog.id,
                                                       includes: { blog in
            [blog.posts]
        }))!
        assertList(queriedBlogWithPost.posts!, state: .isLoaded(count: 1))
        
        // post includes blog
        let queriedPostWithBlog = try await query(.get(Post.self, byIdentifier: post.id, includes: { post in [post.blog] }))!
        assertLazyReference(queriedPostWithBlog._blog, state: .loaded(model: blog))
    }
    
    func testPostIncludesCommentAndCommentIncludesPost() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let post = Post(name: "name", randomId: "randomId")
        try await mutate(.create(post))
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(comment))
        
        // post includes comment
        let queriedPostWithComment = try await query(.get(Post.self, byIdentifier: post.id, includes: { post in [post.comments]}))!
        assertList(queriedPostWithComment.comments!, state: .isLoaded(count: 1))
        
        // comment includes post
        let queriedCommentWithPost = try await query(.get(Comment.self, byIdentifier: comment.id, includes: { comment in [comment.post] }))!
        assertLazyReference(queriedCommentWithPost._post, state: .loaded(model: post))
    }
    
    func testBlogIncludesPostAndCommentAndCommentIncludesPostAndBlog() async throws {
        await setup(withModels: BlogPostComment8V2Models(), logLevel: .verbose)
        let blog = Blog(name: "name")
        try await mutate(.create(blog))
        let post = Post(name: "name", randomId: "randomId", blog: blog)
        try await mutate(.create(post))
        let comment = Comment(content: "content", post: post)
        try await mutate(.create(comment))
        
        // blog includes post and comment
        let queriedBlogWithPostComment = try await query(.get(Blog.self,
                                                       byIdentifier: blog.id,
                                                       includes: { blog in
            [blog.posts.comments]
        }))!
        assertList(queriedBlogWithPostComment.posts!, state: .isLoaded(count: 1))
        assertList(queriedBlogWithPostComment.posts!.first!.comments!, state: .isLoaded(count: 1))
        
        // comment includes post and blog
        let queriedCommentWithPostBlog = try await query(.get(Comment.self, byIdentifier: comment.id, includes: { comment in [comment.post.blog] }))!
        assertLazyReference(queriedCommentWithPostBlog._post, state: .loaded(model: post))
        let loadedPost = try await queriedCommentWithPostBlog.post!
        assertLazyReference(loadedPost._blog, state: .loaded(model: blog))
    }
    
    func testUpdate() {
        
    }
    
    func testDelete() {
        
    }
}

extension GraphQLLazyLoadBlogPostComment8V2Tests: DefaultLogger { }

extension GraphQLLazyLoadBlogPostComment8V2Tests {
    
    typealias Blog = Blog8V2
    typealias Post = Post8V2
    typealias Comment = Comment8V2
    
    struct BlogPostComment8V2Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Blog8V2.self)
            ModelRegistry.register(modelType: Post8V2.self)
            ModelRegistry.register(modelType: Comment8V2.self)
        }
    }
}

