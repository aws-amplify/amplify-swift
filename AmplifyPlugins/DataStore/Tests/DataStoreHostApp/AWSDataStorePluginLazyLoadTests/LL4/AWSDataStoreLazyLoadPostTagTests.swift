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

    typealias Post = PostWithTagsCompositeKey
    typealias Tag = TagWithCompositeKey
    typealias PostTag = PostTagsWithCompositeKey
    
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
        
        guard let queriedPost = try await Amplify.DataStore.query(Post.self,
                                                                  byIdentifier: .identifier(
                                                                    postId: post.postId,
                                                                    title: post.title)) else {
            XCTFail("Failed to query post")
            return
        }
        try await assertPost(queriedPost, canLazyLoad: savedPostTag)
        
        guard let queriedTag = try await Amplify.DataStore.query(Tag.self,
                                                                 byIdentifier: .identifier(
                                                                    id: savedTag.id,
                                                                    name: savedTag.name)) else {
            XCTFail("Failed to query tag")
            return
        }
        try await assertTag(queriedTag, canLazyLoad: savedPostTag)
        
        guard let queriedPostTag = try await Amplify.DataStore.query(PostTag.self,
                                                                     byIdentifier: postTag.id) else {
            XCTFail("Failed to query postTag")
            return
        }
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
    
    
}
extension AWSDataStoreLazyLoadPostTagTests {
    struct PostTagModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostTagsWithCompositeKey.self)
            ModelRegistry.register(modelType: PostWithTagsCompositeKey.self)
            ModelRegistry.register(modelType: TagWithCompositeKey.self)
        }
    }
}
