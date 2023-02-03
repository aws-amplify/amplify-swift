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

    func testStart() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
    }
    
    func testLazyLoad() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        try await assertPost(savedPost, canLazyLoad: savedPostTag)
        try await assertTag(savedTag, canLazyLoad: savedPostTag)
        assertLazyReference(savedPostTag._postWithTagsCompositeKey, state: .loaded(model: savedPost))
        assertLazyReference(savedPostTag._tagWithCompositeKey, state: .loaded(model: savedTag))
        let queriedPost = try await query(for: savedPost)
        try await assertPost(queriedPost, canLazyLoad: savedPostTag)
        let queriedTag = try await query(for: savedTag)
        try await assertTag(queriedTag, canLazyLoad: savedPostTag)
        let queriedPostTag = try await query(for: savedPostTag)
        try await assertPostTag(queriedPostTag, canLazyLoadTag: savedTag, canLazyLoadPost: savedPost)
    }
    
    func assertPost(_ post: Post,
                    canLazyLoad postTag: PostTag) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIds: [post.identifier],
                                                 associatedFields: ["postWithTagsCompositeKey"]))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 1))
    }
    
    func assertTag(_ tag: Tag,
                   canLazyLoad postTag: PostTag) async throws {
        guard let postTags = tag.posts else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIds: [tag.identifier],
                                                 associatedFields: ["tagWithCompositeKey"]))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 1))
    }
    
    func assertPostTag(_ postTag: PostTag, canLazyLoadTag tag: Tag, canLazyLoadPost post: Post) async throws {
        assertLazyReference(postTag._tagWithCompositeKey, state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: tag.identifier)]))
        assertLazyReference(postTag._postWithTagsCompositeKey, state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: post.identifier)]))
        let loadedTag = try await postTag.tagWithCompositeKey
        assertLazyReference(postTag._tagWithCompositeKey, state: .loaded(model: loadedTag))
        try await assertTag(loadedTag, canLazyLoad: postTag)
        let loadedPost = try await postTag.postWithTagsCompositeKey
        assertLazyReference(postTag._postWithTagsCompositeKey, state: .loaded(model: loadedPost))
        try await assertPost(loadedPost, canLazyLoad: postTag)
    }
    
    func testUpdate() async throws {
        await setup(withModels: PostTagModels())
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        let savedPostTag = try await saveAndWaitForSync(postTag)
        
        // update the post tag with a new post
        var queriedPostTag = try await query(for: savedPostTag)
        let newPost = Post(postId: UUID().uuidString, title: "title")
        _ = try await saveAndWaitForSync(newPost)
        queriedPostTag.setPostWithTagsCompositeKey(newPost)
        let savedPostTagWithNewPost = try await saveAndWaitForSync(queriedPostTag, assertVersion: 2)
        assertLazyReference(savedPostTagWithNewPost._postWithTagsCompositeKey, state: .loaded(model: newPost))
        let queriedPreviousPost = try await query(for: savedPost)
        try await assertPostWithNoPostTag(queriedPreviousPost)
        
        // update the post tag with a new tag
        var queriedPostTagWithNewPost = try await query(for: savedPostTagWithNewPost)
        let newTag = Tag(name: "name")
        _ = try await saveAndWaitForSync(newTag)
        queriedPostTagWithNewPost.setTagWithCompositeKey(newTag)
        let savedPostTagWithNewTag = try await saveAndWaitForSync(queriedPostTagWithNewPost, assertVersion: 3)
        assertLazyReference(savedPostTagWithNewTag._tagWithCompositeKey, state: .loaded(model: newTag))
        let queriedPreviousTag = try await query(for: savedTag)
        try await assertTagWithNoPostTag(queriedPreviousTag)
    }
    
    func assertPostWithNoPostTag(_ post: Post) async throws {
        guard let postTags = post.tags else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIds: [post.identifier],
                                                 associatedFields: ["postWithTagsCompositeKey"]))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func assertTagWithNoPostTag(_ tag: Tag) async throws {
        guard let postTags = tag.posts else {
            XCTFail("Missing postTags on post")
            return
        }
        assertList(postTags, state: .isNotLoaded(associatedIds: [tag.identifier],
                                                 associatedFields: ["tagWithCompositeKey"]))
        try await postTags.fetch()
        assertList(postTags, state: .isLoaded(count: 0))
    }
    
    func testDeletePost() async throws {
        await setup(withModels: PostTagModels())
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
        await setup(withModels: PostTagModels())
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
        await setup(withModels: PostTagModels())
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
    
    func testObservePost() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedPost = try? mutationEvent.decodeModel(as: Post.self),
                   receivedPost.postId == post.postId {
                    
                    guard let tags = receivedPost.tags else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await tags.fetch()
                    } catch {
                        XCTFail("Failed to lazy load \(error)")
                    }
                    XCTAssertEqual(tags.count, 0)
                    
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
    
    func testObserveTag() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let tag = Tag(name: "name")
        
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(Tag.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedTag = try? mutationEvent.decodeModel(as: Tag.self),
                   receivedTag.id == tag.id {
                    guard let posts = receivedTag.posts else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await posts.fetch()
                    } catch {
                        XCTFail("Failed to lazy load \(error)")
                    }
                    XCTAssertEqual(posts.count, 0)
                    
                    await mutationEventReceived.fulfill()
                }
            }
        }
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: tag, modelSchema: Tag.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObservePostTag() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        let savedPost = try await saveAndWaitForSync(post)
        let savedTag = try await saveAndWaitForSync(tag)
        
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(PostTag.self)
        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedPostTag = try? mutationEvent.decodeModel(as: PostTag.self),
                   receivedPostTag.id == postTag.id {
                    
                    try await assertPostTag(receivedPostTag, canLazyLoadTag: tag, canLazyLoadPost: post)
                    await mutationEventReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: postTag, modelSchema: PostTag.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }
    
    func testObserveQueryPost() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Post.self, where: Post.keys.postId == post.postId)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedPost = querySnapshot.items.first {
                    guard let tags = receivedPost.tags else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await tags.fetch()
                    } catch {
                        XCTFail("Failed to lazy load \(error)")
                    }
                    XCTAssertEqual(tags.count, 0)
                    
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
    
    func testObserveQueryTag() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let tag = Tag(name: "name")
        
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Tag.self, where: Tag.keys.id == tag.id)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedTag = querySnapshot.items.first {
                    guard let posts = receivedTag.posts else {
                        XCTFail("Lazy List does not exist")
                        return
                    }
                    do {
                        try await posts.fetch()
                    } catch {
                        XCTFail("Failed to lazy load \(error)")
                    }
                    XCTAssertEqual(posts.count, 0)
                    
                    await snapshotReceived.fulfill()
                }
            }
        }
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: tag, modelSchema: Tag.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
    }
    
    func testObserveQueryPostTag() async throws {
        await setup(withModels: PostTagModels())
        try await startAndWaitForReady()
        let post = Post(postId: UUID().uuidString, title: "title")
        let tag = Tag(name: "name")
        try await saveAndWaitForSync(post)
        try await saveAndWaitForSync(tag)
        
        let postTag = PostTag(postWithTagsCompositeKey: post, tagWithCompositeKey: tag)
        
        let snapshotReceived = asyncExpectation(description: "Received query snapshot")
        let querySnapshots = Amplify.DataStore.observeQuery(for: PostTag.self, where: PostTag.keys.id == postTag.id)
        Task {
            for try await querySnapshot in querySnapshots {
                if let receivedPostTag = querySnapshot.items.first {
                    try await assertPostTag(receivedPostTag, canLazyLoadTag: tag, canLazyLoadPost: post)
                    await snapshotReceived.fulfill()
                }
            }
        }
        
        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: postTag, modelSchema: PostTag.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }
        
        await waitForExpectations([snapshotReceived], timeout: 60)
        querySnapshots.cancel()
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
}
