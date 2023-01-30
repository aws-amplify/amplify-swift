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

final class GraphQLLazyLoadPostTagTests: GraphQLLazyLoadBaseTest {
    
    func testLazyLoad() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await mutate(.create(post))
        let savedTag = try await mutate(.create(tag))
        let savedPostTag = try await mutate(.create(postTag))
        
        try await assertPost(savedPost, canLazyLoad: savedPostTag)
        try await assertTag(savedTag, canLazyLoad: savedPostTag)
        try await assertPostTag(savedPostTag, canLazyLoadTag: savedTag, canLazyLoadPost: savedPost)
        
        let queriedPost = try await query(.get(Post.self, byIdentifier: .identifier(postId: post.postId, title: post.title)))!
        try await assertPost(queriedPost, canLazyLoad: savedPostTag)
        let queriedTag = try await query(for: savedTag)!
        try await assertTag(queriedTag, canLazyLoad: savedPostTag)
        let request = GraphQLRequest<PostTag?>.get(PostTag.self, byIdentifier: savedPostTag.id)
        let expectedDocument = """
        query GetPostTagsWithCompositeKey($id: ID!) {
          getPostTagsWithCompositeKey(id: $id) {
            id
            createdAt
            updatedAt
            postWithTagsCompositeKey {
              postId
              title
              __typename
            }
            tagWithCompositeKey {
              id
              name
              __typename
            }
            __typename
          }
        }
        """
        XCTAssertEqual(request.document, expectedDocument)
        let queriedPostTag = try await query(request)!
        
        try await assertPostTag(queriedPostTag, canLazyLoadTag: savedTag, canLazyLoadPost: savedPost)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad postTag: PostTag) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title],
                                                 associatedField: "postWithTagsCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 1))
    }
    
    func assertTag(_ tag: Tag,
                   canLazyLoad postTag: PostTag) async throws {
        guard let postTags = tag.posts else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIdentifiers: [tag.id, tag.name],
                                                 associatedField: "tagWithCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 1))
    }
    
    func assertPostTag(_ postTag: PostTag, canLazyLoadTag tag: Tag, canLazyLoadPost post: Post) async throws {
        assertLazyReference(postTag._tagWithCompositeKey, state: .notLoaded(identifiers: [.init(name: "id", value: tag.id),
                                                                                      .init(name: "name", value: tag.name)]))
        assertLazyReference(postTag._postWithTagsCompositeKey, state: .notLoaded(identifiers: [.init(name: "postId", value: post.postId),
                                                                                           .init(name: "title", value: post.title)]))
        let loadedTag = try await postTag.tagWithCompositeKey
        assertLazyReference(postTag._tagWithCompositeKey, state: .loaded(model: loadedTag))
        try await assertTag(loadedTag, canLazyLoad: postTag)
        let loadedPost = try await postTag.postWithTagsCompositeKey
        assertLazyReference(postTag._postWithTagsCompositeKey, state: .loaded(model: loadedPost))
        try await assertPost(loadedPost, canLazyLoad: postTag)
    }
    
    func testIncludesNestedModel() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        try await mutate(.create(post))
        try await mutate(.create(tag))
        try await mutate(.create(postTag))
        
        guard let queriedPost = try await query(.get(Post.self,
                                                     byIdentifier: .identifier(postId: post.postId,
                                                                               title: post.title),
                                                     includes: { post in [post.tags] })) else {
            XCTFail("Could not perform nested query for Post")
            return
        }
        guard var tags = queriedPost.tags else {
            XCTFail("Could not get queriedPost's tags")
            return
        }
        while tags.hasNextPage() {
            tags = try await tags.getNextPage()
        }
        XCTAssertEqual(tags.count, 1)
        
        guard let queriedTag = try await query(.get(Tag.self,
                                                    byIdentifier: .identifier(id: tag.id,
                                                                              name: tag.name),
                                                    includes: { tag in [tag.posts] })) else {
            XCTFail("Could not perform nested query for Tag")
            return
        }
        guard var posts = queriedTag.posts else {
            XCTFail("Could not get queriedTag's posts")
            return
        }
        while posts.hasNextPage() {
            posts = try await posts.getNextPage()
        }
        XCTAssertEqual(posts.count, 1)
        
        guard let queriedPostTag = try await query(.get(PostTag.self,
                                                        byIdentifier: postTag.id,
                                                        includes: { postTag in [
                                                            postTag.postWithTagsCompositeKey,
                                                            postTag.tagWithCompositeKey] })) else {
            XCTFail("Could not perform nested query for PostTag")
            return
        }
        
        assertLazyReference(queriedPostTag._postWithTagsCompositeKey, state: .loaded(model: post))
        assertLazyReference(queriedPostTag._tagWithCompositeKey, state: .loaded(model: tag))
    }
    
    func testListPostListTagListPostTag() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        try await mutate(.create(post))
        try await mutate(.create(tag))
        try await mutate(.create(postTag))
        
        let queriedPosts = try await listQuery(.list(Post.self, where: Post.keys.postId == post.postId))
        assertList(queriedPosts, state: .isLoaded(count: 1))
        assertList(queriedPosts.first!.tags!,
                   state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title], associatedField: "postWithTagsCompositeKey"))
        
        let queriedTags = try await listQuery(.list(Tag.self, where: Tag.keys.id == tag.id))
        assertList(queriedTags, state: .isLoaded(count: 1))
        assertList(queriedTags.first!.posts!,
                   state: .isNotLoaded(associatedIdentifiers: [tag.id, tag.name], associatedField: "tagWithCompositeKey"))
        
        let queriedPostTags = try await listQuery(.list(PostTag.self, where: PostTag.keys.id == postTag.id))
        assertList(queriedPostTags, state: .isLoaded(count: 1))
        assertLazyReference(queriedPostTags.first!._postWithTagsCompositeKey,
                            state: .notLoaded(identifiers: [
                                .init(name: "postId", value: post.postId),
                                .init(name: "title", value: post.title)]))
        assertLazyReference(queriedPostTags.first!._tagWithCompositeKey,
                            state: .notLoaded(identifiers: [
                                .init(name: "id", value: tag.id),
                                .init(name: "name", value: tag.name)]))
    }
    
    func testUpdate() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await mutate(.create(post))
        let savedTag = try await mutate(.create(tag))
        let savedPostTag = try await mutate(.create(postTag))
        
        // update the post tag with a new post
        var queriedPostTag = try await query(for: savedPostTag)!
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await mutate(.create(newPost))
        queriedPostTag.setPostWithTagsCompositeKey(newPost)
        let savedPostTagWithNewPost = try await mutate(.update(queriedPostTag, includes: { postTag in [postTag.postWithTagsCompositeKey] }))
        assertLazyReference(savedPostTagWithNewPost._postWithTagsCompositeKey, state: .loaded(model: newPost))
        let queriedPreviousPost = try await query(for: post)!
        try await assertPostWithNoPostTag(queriedPreviousPost)
        
        // update the post tag with a new tag
        var queriedPostTagWithNewPost = try await query(for: savedPostTagWithNewPost)!
        let newTag = Tag(name: "name")
        _ = try await mutate(.create(newTag))
        queriedPostTagWithNewPost.setTagWithCompositeKey(newTag)
        let savedPostTagWithNewTag = try await mutate(.update(queriedPostTagWithNewPost, includes: { postTag in [postTag.tagWithCompositeKey]}))
        assertLazyReference(savedPostTagWithNewTag._tagWithCompositeKey, state: .loaded(model: newTag))
        let queriedPreviousTag = try await query(for: savedTag)!
        try await assertTagWithNoPostTag(queriedPreviousTag)
    }
    
    func assertPostWithNoPostTag(_ post: Post) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIdentifiers: [post.postId, post.title],
                                                 associatedField: "postWithTagsCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func assertTagWithNoPostTag(_ tag: Tag) async throws {
        guard let postTags = tag.posts else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIdentifiers: [tag.id, tag.name],
                                                 associatedField: "tagWithCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func testDeletePost() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let savedPost = try await mutate(.create(post))
        
        try await mutate(.delete(savedPost))
        try await assertModelDoesNotExist(savedPost)
    }
    
    func testDeleteTag() async throws {
        await setup(withModels: PostTagModels())
        let tag = Tag(name: "name")
        let savedTag = try await mutate(.create(tag))
        
        try await mutate(.delete(savedTag))
        try await assertModelDoesNotExist(savedTag)
    }
    
    func testDeletePostTag() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await mutate(.create(post))
        let savedTag = try await mutate(.create(tag))
        let savedPostTag = try await mutate(.create(postTag))
        
        try await mutate(.delete(savedPostTag))
        
        try await assertModelExists(savedPost)
        try await assertModelExists(savedTag)
        try await assertModelDoesNotExist(savedPostTag)
    }
}

extension GraphQLLazyLoadPostTagTests: DefaultLogger { }

extension GraphQLLazyLoadPostTagTests {
    typealias Post = PostWithTagsCompositeKey
    typealias Tag = TagWithCompositeKey
    typealias PostTag = PostTagsWithCompositeKey
    
    struct PostTagModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostTagsWithCompositeKey.self)
            ModelRegistry.register(modelType: PostWithTagsCompositeKey.self)
            ModelRegistry.register(modelType: TagWithCompositeKey.self)
        }
    }
}
