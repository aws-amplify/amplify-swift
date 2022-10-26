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

final class AWSDataStoreLazyLoadPostTagTests: AWSDataStoreLazyLoadBaseTest {

    func testLazyLoad() async throws {
        await setup(withModels: PostTagModels(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        try await assertPost(savedPost, canLazyLoad: savedPostTag)
        try await assertTag(savedTag, canLazyLoad: savedPostTag)
        assertLazyModel(savedPostTag._postWithTagsCompositeKey, state: .loaded(model: savedPost))
        assertLazyModel(savedPostTag._tagWithCompositeKey, state: .loaded(model: savedTag))
        let queriedPost = try await queryPost(savedPost)
        try await assertPost(queriedPost, canLazyLoad: savedPostTag)
        let queriedTag = try await queryTag(savedTag)
        try await assertTag(queriedTag, canLazyLoad: savedPostTag)
        let queriedPostTag = try await queryPostTag(savedPostTag)
        try await assertPostTag(queriedPostTag, canLazyLoadTag: savedTag, canLazyLoadPost: savedPost)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad postTag: PostTag) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedId: post.identifier,
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
        assertList(postTags, state: .isNotLoaded(associatedId: tag.identifier,
                                                 associatedField: "tagWithCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 1))
    }
    
    func assertPostTag(_ postTag: PostTag, canLazyLoadTag tag: Tag, canLazyLoadPost post: Post) async throws {
        assertLazyModel(postTag._tagWithCompositeKey, state: .notLoaded(identifiers: ["@@primaryKey": tag.identifier]))
        assertLazyModel(postTag._postWithTagsCompositeKey, state: .notLoaded(identifiers: ["@@primaryKey": post.identifier]))
        let loadedTag = try await postTag.tagWithCompositeKey
        assertLazyModel(postTag._tagWithCompositeKey, state: .loaded(model: loadedTag))
        try await assertTag(loadedTag, canLazyLoad: postTag)
        let loadedPost = try await postTag.postWithTagsCompositeKey
        assertLazyModel(postTag._postWithTagsCompositeKey, state: .loaded(model: loadedPost))
        try await assertPost(loadedPost, canLazyLoad: postTag)
    }
    
    func testUpdate() async throws {
        await setup(withModels: PostTagModels(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        // update the post tag with a new post
        var queriedPostTag = try await queryPostTag(savedPostTag)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedPostTag.setPostWithTagsCompositeKey(newPost)
        let savedPostTagWithNewPost = try await saveAndWaitForSync(queriedPostTag, assertVersion: 2)
        assertLazyModel(savedPostTagWithNewPost._postWithTagsCompositeKey, state: .loaded(model: newPost))
        let queriedPreviousPost = try await queryPost(savedPost)
        try await assertPostWithNoPostTag(queriedPreviousPost)
        
        // update the post tag with a new tag
        var queriedPostTagWithNewPost = try await queryPostTag(savedPostTagWithNewPost)
        let newTag = Tag(name: "name")
        _ = try await saveAndWaitForSync(newTag)
        queriedPostTagWithNewPost.setTagWithCompositeKey(newTag)
        let savedPostTagWithNewTag = try await saveAndWaitForSync(queriedPostTagWithNewPost, assertVersion: 3)
        assertLazyModel(savedPostTagWithNewTag._tagWithCompositeKey, state: .loaded(model: newTag))
        let queriedPreviousTag = try await queryTag(savedTag)
        try await assertTagWithNoPostTag(queriedPreviousTag)
    }
    
    func assertPostWithNoPostTag(_ post: Post) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedId: post.identifier,
                                                 associatedField: "postWithTagsCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func assertTagWithNoPostTag(_ tag: Tag) async throws {
        guard let postTags = tag.posts else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedId: tag.identifier,
                                                 associatedField: "tagWithCompositeKey"))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func testDeletePost() async throws {
        await setup(withModels: PostTagModels(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        try await deleteAndWaitForSync(savedPost)
        
        try await assertModelDoesNotExist(savedPost)
        try await assertModelExists(savedTag)
        try await assertModelDoesNotExist(savedPostTag)
    }
    
    func testDeleteTag() async throws {
        await setup(withModels: PostTagModels(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        try await deleteAndWaitForSync(savedTag)
        
        try await assertModelExists(savedPost)
        try await assertModelDoesNotExist(savedTag)
        try await assertModelDoesNotExist(savedPostTag)
    }
    
    func testDeletePostTag() async throws {
        await setup(withModels: PostTagModels(), logLevel: .verbose, eagerLoad: false)
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        try await deleteAndWaitForSync(savedPostTag)
        
        try await assertModelExists(savedPost)
        try await assertModelExists(savedTag)
        try await assertModelDoesNotExist(savedPostTag)
    }
}
extension AWSDataStoreLazyLoadPostTagTests {
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
    
    func queryPost(_ post: Post) async throws -> Post {
        guard let queriedPost = try await Amplify.DataStore.query(Post.self,
                                                                  byIdentifier: .identifier(
                                                                    postId: post.postId,
                                                                    title: post.title)) else {
            XCTFail("Failed to query post")
            throw "Failed to query post"
        }
        return queriedPost
    }
    
    func queryTag(_ tag: Tag) async throws -> Tag {
        guard let queriedTag = try await Amplify.DataStore.query(Tag.self,
                                                                 byIdentifier: .identifier(
                                                                    id: tag.id,
                                                                    name: tag.name)) else {
            XCTFail("Failed to query tag")
            throw "Failed to query tag"
        }
        return queriedTag
    }
    
    func queryPostTag(_ postTag: PostTag) async throws -> PostTag {
        guard let queriedPostTag = try await Amplify.DataStore.query(PostTag.self,
                                                                     byIdentifier: postTag.id) else {
            XCTFail("Failed to query postTag")
            throw "Failed to query postTag"
        }
        return queriedPostTag
    }
    
}
