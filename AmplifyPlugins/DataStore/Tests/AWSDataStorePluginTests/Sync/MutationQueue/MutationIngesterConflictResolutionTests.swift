//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// TODO: Split these tests into separate suites

/// Tests in this class have a naming convention of `test_<existing>_<candidate>`, which is to say: given that the
/// mutation queue has an existing record of type `<existing>`, assert the behavior when candidate a mutation of
/// type `<candidate>`.
class MutationIngesterConflictResolutionTests: SyncEngineTestBase {

    // MARK: - Existing == .create

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_create_create() async {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .create, for: post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        do {
            _ = try await Amplify.DataStore.save(post)
            XCTFail("Should have caught error")
        } catch {
            XCTAssertNotNil(error)
        }

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 1)
                                    let firstEventJSON = mutationEvents[0].json
                                    let firstEventData = Data(firstEventJSON.utf8)
                                    guard let mutationEventPost = try? JSONDecoder().decode(
                                        Post.self, from: firstEventData
                                    ) else {
                                        return XCTFail("expected Post")
                                    }
                                    XCTAssertEqual(mutationEventPost.id, post.id)
                                    XCTAssertEqual(mutationEventPost.title, post.title)
                                    XCTAssertEqual(mutationEventPost.content, post.content)
                                    XCTAssertEqual(mutationEventPost.createdAt, post.createdAt)
                                }
                                mutationEventVerified.fulfill()
        }

        await fulfillment(of: [mutationEventVerified], timeout: 1)
    }

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is updated with the new values
    func test_create_update() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .create, for: post)
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let savedPost = try await Amplify.DataStore.save(mutatedPost)
        XCTAssertEqual(savedPost.content, mutatedPost.content)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                guard let mutationEvent = mutationEvents.first else {
                    XCTFail("mutationEvents empty or nil")
                    return
                }
                guard let mutationEventPost = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost.content, mutatedPost.content)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.create.rawValue)
            }
            mutationEventVerified.fulfill()
        }
        
        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .create
    /// - When:
    ///    - I submit a .delete MutationEvent for the same object
    /// - Then:
    ///    - The delete is saved to DataStore
    ///    - The mutation event is removed from the mutation queue
    func test_create_delete() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .create, for: post)
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }
        
        try await Amplify.DataStore.delete(post)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 0)
                                }
                                mutationEventVerified.fulfill()
        }

        await fulfillment(of: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Existing == .update

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_update_create() async {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .update, for: post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        do {
            _ = try await Amplify.DataStore.save(post)
            XCTFail("Should have caught error")
        } catch {
            XCTAssertNotNil(error)
        }

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    XCTAssertEqual(mutationEvents.count, 1)
                                    XCTAssertEqual(mutationEvents.first?.mutationType,
                                                   GraphQLMutationType.update.rawValue)
                                    let firstEventJSON = mutationEvents[0].json
                                    let firstEventData = Data(firstEventJSON.utf8)
                                    guard let mutationEventPost = try? JSONDecoder().decode(
                                        Post.self, from: firstEventData
                                    ) else {
                                        return XCTFail("expected Post")
                                    }
                                    XCTAssertEqual(mutationEventPost.id, post.id)
                                    XCTAssertEqual(mutationEventPost.title, post.title)
                                    XCTAssertEqual(mutationEventPost.content, post.content)
                                    XCTAssertEqual(mutationEventPost.createdAt, post.createdAt)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is updated with the new values
    func test_update_update() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .update, for: post)
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let savedPost = try await Amplify.DataStore.save(mutatedPost)
        XCTAssertEqual(savedPost.content, mutatedPost.content)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                guard let mutationEvent = mutationEvents.first else {
                    XCTFail("mutationEvents empty or nil")
                    return
                }
                guard let mutationEventPost = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost.content, mutatedPost.content)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.update.rawValue)
            }
            mutationEventVerified.fulfill()
        }
        
        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An existing MutationEvent of type .update
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - The delete is saved to DataStore
    ///    - The mutation event is updated to a .delete type
    func test_update_delete() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .update, for: post)
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }
        
        try await Amplify.DataStore.delete(post)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    guard let mutationEvent = mutationEvents.first else {
                                        XCTFail("mutationEvents empty or nil")
                                        return
                                    }
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Existing == .delete

    /// - Given: An existing MutationEvent of type .delete
    /// - When:
    ///    - I submit a .create MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_delete_create() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .delete, for: post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        do {
            _ = try await Amplify.DataStore.save(post)
            XCTFail("Should have caught error")
        } catch {
            XCTAssertNotNil(error)
        }

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    guard let mutationEvent = mutationEvents.first else {
                                        XCTFail("mutationEvents empty or nil")
                                        return
                                    }
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // test_<existing>_<candidate>
    /// - Given: An existing MutationEvent of type .delete
    /// - When:
    ///    - I submit a .update MutationEvent for the same object
    /// - Then:
    ///    - I receive an error
    ///    - The mutation queue retains the original event
    func test_delete_update() async {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try saveMutationEvent(of: .delete, for: post)
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        do {
            _ = try await Amplify.DataStore.save(mutatedPost)
            XCTFail("Should have caught error")
        } catch {
            XCTAssertNotNil(error)
        }

        let mutationEventVerified = expectation(description: "Verified mutation event")
        let predicate = MutationEvent.keys.id == SyncEngineTestBase.mutationEventId(for: post)
        storageAdapter.query(MutationEvent.self,
                             predicate: predicate) { result in
                                switch result {
                                case .failure(let dataStoreError):
                                    XCTAssertNil(dataStoreError)
                                case .success(let mutationEvents):
                                    guard let mutationEvent = mutationEvents.first else {
                                        XCTFail("mutationEvents empty or nil")
                                        return
                                    }
                                    XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
                                }
                                mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - Empty queue tests

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .create mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testCreateMutationAppendedToEmptyQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        let savedPost = try await Amplify.DataStore.save(post)
        XCTAssertNotNil(savedPost)
        
        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                guard let mutationEvent = mutationEvents.first else {
                    XCTFail("mutationEvents empty or nil")
                    return
                }
                guard let mutationEventPost = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost.id, savedPost.id)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.create.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .update mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testUpdateMutationAppendedToEmptyQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        let savedPost = try await Amplify.DataStore.save(post)
        XCTAssertNotNil(savedPost)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                guard let mutationEvent = mutationEvents.first else {
                    XCTFail("mutationEvents empty or nil")
                    return
                }
                guard let mutationEventPost = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost.id, savedPost.id)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.update.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: An empty mutation queue
    /// - When:
    ///    - I perform a .delete mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue
    func testDeleteMutationAppendedToEmptyQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try savePost(post)
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
        }

        try await Amplify.DataStore.delete(post)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                guard let mutationEvent = mutationEvents.first else {
                    XCTFail("mutationEvents empty or nil")
                    return
                }
                XCTAssertEqual(mutationEvent.modelId, post.id)
                XCTAssertEqual(mutationEvent.mutationType, GraphQLMutationType.delete.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        wait(for: [mutationEventVerified], timeout: 1.0)
    }

    // MARK: - In-process queue tests

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .create mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have thrown an error
    func testCreateMutationAppendedToInProcessQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
            try saveMutationEvent(of: .create, for: post, inProcess: true)
        }

        let savedPost = try await Amplify.DataStore.save(post)
        XCTAssertNotNil(savedPost)
        
        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.create.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        await fulfillment(of: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .update mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have overwritten the existing
    ///      create
    func testUpdateMutationAppendedToInProcessQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
            try savePost(post)
            try saveMutationEvent(of: .create, for: post, inProcess: true)
        }

        var mutatedPost = post
        mutatedPost.content = "UPDATED CONTENT"
        let savedPost = try await Amplify.DataStore.save(mutatedPost)
        XCTAssertEqual(savedPost.content, mutatedPost.content)

        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                guard let mutationEventPost1 = try? mutationEvents[0].decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost1.id, savedPost.id)

                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.update.rawValue)
                guard let mutationEventPost2 = try? mutationEvents[1].decodeModel(as: Post.self) else {
                    XCTFail("Could not decode mutation event json to Post instance")
                    return
                }
                XCTAssertEqual(mutationEventPost2.id, mutatedPost.id)
                XCTAssertEqual(mutationEventPost2.content, mutatedPost.content)
            }
            mutationEventVerified.fulfill()
        }

        await fulfillment(of: [mutationEventVerified], timeout: 1.0)
    }

    /// - Given: A mutation queue with an in-process .create event
    /// - When:
    ///    - I perform a .delete mutation
    /// - Then:
    ///    - The update is saved to DataStore
    ///    - The mutation event is appended to the queue, even though it would normally have thrown an error
    func testDeleteMutationAppendedToInProcessQueue() async throws {
        let post = Post(id: "post-1",
                        title: "title",
                        content: "content",
                        createdAt: .now())

        await tryOrFail {
            try setUpStorageAdapter(preCreating: [Post.self, Comment.self])
            try setUpDataStore()
            try await startAmplifyAndWaitForSync()
            try savePost(post)
            try saveMutationEvent(of: .create, for: post, inProcess: true)
        }

        try await Amplify.DataStore.delete(post)
        
        let mutationEventVerified = expectation(description: "Verified mutation event")
        storageAdapter.query(MutationEvent.self, predicate: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                XCTAssertNil(dataStoreError)
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                XCTAssertEqual(mutationEvents[0].mutationType, GraphQLMutationType.create.rawValue)
                XCTAssertEqual(mutationEvents[1].mutationType, GraphQLMutationType.delete.rawValue)
            }
            mutationEventVerified.fulfill()
        }

        await fulfillment(of: [mutationEventVerified], timeout: 1.0)
    }

}
