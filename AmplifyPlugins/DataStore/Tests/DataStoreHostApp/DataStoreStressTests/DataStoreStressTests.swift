//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore
import Combine
import AWSAPIPlugin

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

final class DataStoreStressTests: DataStoreStressBaseTest {
    
    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
        }

        let version: String = "1"
    }
    
    // MARK: - Stress tests
    
    /// Perform concurrent saves and observe the data successfuly synced from cloud
    ///
    /// - Given: DataStore is in ready state
    /// - When:
    ///    - Concurrently perform Datastore.save() from 50 tasks
    /// - Then:
    ///    - Ensure the expected mutation event with version 1 (synced from cloud) is received
    ///
    func testMultipleSave() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startDataStoreAndWaitForReady()

        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            status: .active,
                            content: "content \(index)",
                            createdAt: .now())
            posts.append(post)
        }
        
        let postsSyncedToCloud = expectation(description: "All posts saved and synced to cloud")
        postsSyncedToCloud.expectedFulfillmentCount = concurrencyLimit

        let postsCopy = posts
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloud.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        let capturedPosts = posts

        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                _ = try await Amplify.DataStore.save(capturedPosts[index])
            }
        }
        
        await fulfillment(of: [postsSyncedToCloud], timeout: networkTimeout)
    }
    
    /// Perform concurrent saves and observe the data successfuly synced from cloud
    ///
    /// - Given: DataStore is in ready state
    /// - When:
    ///    - Concurrently perform Datastore.save() from 50 tasks and Datastore.query(model:byId:) from 50 tasks
    /// - Then:
    ///    - Ensure the expected mutation event with version 1 (synced from cloud) is received
    ///    - Query for the item is successful
    ///
    func testMultipleQueryByID() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startDataStoreAndWaitForReady()

        let posts = await saveAndSyncPosts(concurrencyLimit: concurrencyLimit)
        
        let localQueryForPosts = expectation(description: "Query for the post is successful")
        localQueryForPosts.expectedFulfillmentCount = concurrencyLimit

        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let queriedPost = try await Amplify.DataStore.query(Post.self, byId: posts[index].id)
                XCTAssertNotNil(queriedPost)
                XCTAssertEqual(posts[index].id, queriedPost?.id)
                XCTAssertEqual(posts[index].title, queriedPost?.title)
                XCTAssertEqual(posts[index].content, queriedPost?.content)
                localQueryForPosts.fulfill()
            }
        }
        
        await fulfillment(of: [localQueryForPosts], timeout: networkTimeout)
    }
    
    /// Perform concurrent saves and observe the data successfuly synced from cloud
    ///
    /// - Given: DataStore is in ready state
    /// - When:
    ///    - Concurrently perform Datastore.save() from 50 tasks and Datastore.query(model:where:) from 50 tasks
    /// - Then:
    ///    - Ensure the expected mutation event with version 1 (synced from cloud) is received
    ///    - Query for the item is successful
    ///
    func testMultipleQueryByPredicate() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startDataStoreAndWaitForReady()

        let posts = await saveAndSyncPosts(concurrencyLimit: concurrencyLimit)
        
        let localQueryForPosts = expectation(description: "Query for the post is successful")
        localQueryForPosts.expectedFulfillmentCount = concurrencyLimit
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let predicate = Post.keys.id.eq(posts[index].id).and(Post.keys.title.eq(posts[index].title))
                let queriedPosts = try await Amplify.DataStore.query(Post.self, where: predicate)
                XCTAssertNotNil(queriedPosts)
                XCTAssertEqual(queriedPosts.count, 1)
                XCTAssertEqual(posts[index].id, queriedPosts[0].id)
                XCTAssertEqual(posts[index].title, queriedPosts[0].title)
                XCTAssertEqual(posts[index].content, queriedPosts[0].content)
                localQueryForPosts.fulfill()
            }
        }
        
        await fulfillment(of: [localQueryForPosts], timeout: networkTimeout)
    }
    
    /// Perform concurrent saves and observe the data successfuly synced from cloud. Then delete the items afterwards
    /// and ensure they have successfully synced from cloud
    ///
    /// - Given: DataStore is in ready state
    /// - When:
    ///    - Concurrently perform Datastore.save() from 50 tasks and then delete the posts from 50 tasks
    /// - Then:
    ///    - Ensure the expected mutation event with version 1 (synced from cloud) is received
    ///    - Clean up: Concurrently perform Delete's
    ///    - Ensure the expected mutation event with version 2 (synced from cloud) is received
    ///
    func testMultipleDelete() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try await startDataStoreAndWaitForReady()
        
        let posts = await saveAndSyncPosts(concurrencyLimit: concurrencyLimit)
        
        let postsDeletedLocally = expectation(description: "All posts deleted locally")
        postsDeletedLocally.expectedFulfillmentCount = concurrencyLimit
        
        let postsDeletedFromCloud = expectation(description: "All posts deleted and synced to cloud")
        postsDeletedFromCloud.expectedFulfillmentCount = concurrencyLimit

        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            do {
                for try await mutationEvent in mutationEvents {
                    guard posts.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }
                    
                    if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                       mutationEvent.version == 1 {
                        postsDeletedLocally.fulfill()
                    } else if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                              mutationEvent.version == 2 {
                        postsDeletedFromCloud.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                try await Amplify.DataStore.delete(posts[index])
            }
        }
        
        await fulfillment(of: [postsDeletedLocally, postsDeletedFromCloud], timeout: networkTimeout)
    }
    
    
    // MARK: - Helpers
    
    func saveAndSyncPosts(concurrencyLimit: Int) async -> [Post] {
        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            status: .active,
                            content: "content \(index)",
                            createdAt: .now())
            posts.append(post)
        }
        
        let postsSyncedToCloud = expectation(description: "All posts saved and synced to cloud")
        postsSyncedToCloud.expectedFulfillmentCount = concurrencyLimit

        let postsCopy = posts
        let mutationEvents = Amplify.DataStore.observe(Post.self)
        Task {
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }
                    
                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloud.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        let capturedPosts = posts
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                _ = try await Amplify.DataStore.save(capturedPosts[index])
            }
        }
        await fulfillment(of: [postsSyncedToCloud], timeout: networkTimeout)
        
        return capturedPosts
    }
}
