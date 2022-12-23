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

final class DataStoreStressTests: XCTestCase {

    static let amplifyConfigurationFile = "testconfiguration/AWSDataStoreStressTests-amplifyconfiguration"
    let concurrencyLimit = 50

    let networkTimeout = TimeInterval(180)
    
    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    func setUp(withModels models: AmplifyModelRegistration, logLevel: LogLevel = .error) async {
        continueAfterFailure = false
        await Amplify.reset()
        Amplify.Logging.logLevel = logLevel

        do {
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
        } catch {
            XCTFail(String(describing: error))
            return
        }
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
        try await startAmplifyAndWaitForSync()

        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            content: "content",
                            createdAt: .now())
            posts.append(post)
        }
        
        let postsSyncedToCloud = asyncExpectation(description: "All posts saved and synced to cloud",
                                                  expectedFulfillmentCount: concurrencyLimit)

        let postsCopy = posts
        Task {
            var postsSyncedToCloudCount = 0
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloudCount += 1
                        await postsSyncedToCloud.fulfill()
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
        
        await waitForExpectations([postsSyncedToCloud], timeout: networkTimeout)
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
        try await startAmplifyAndWaitForSync()

        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            content: "content",
                            createdAt: .now())
            posts.append(post)
        }
        let postsSyncedToCloud = asyncExpectation(description: "All posts saved and synced to cloud",
                                                  expectedFulfillmentCount: concurrencyLimit)

        let postsCopy = posts
        Task {
            var postsSyncedToCloudCount = 0
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloudCount += 1
                        await postsSyncedToCloud.fulfill()
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
        
        await waitForExpectations([postsSyncedToCloud], timeout: networkTimeout)
        
        let localQueryForPosts = asyncExpectation(description: "Query for the post is successful",
                                                expectedFulfillmentCount: concurrencyLimit)
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let queriedPost = try await Amplify.DataStore.query(Post.self, byId: capturedPosts[index].id)
                XCTAssertNotNil(queriedPost)
                XCTAssertEqual(capturedPosts[index].id, queriedPost?.id)
                XCTAssertEqual(capturedPosts[index].title, queriedPost?.title)
                XCTAssertEqual(capturedPosts[index].content, queriedPost?.content)
                await localQueryForPosts.fulfill()
            }
        }
        
        await waitForExpectations([localQueryForPosts], timeout: networkTimeout)
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
        try await startAmplifyAndWaitForSync()

        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            content: "content",
                            createdAt: .now())
            posts.append(post)
        }
        let postsSyncedToCloud = asyncExpectation(description: "All posts saved and synced to cloud",
                                                  expectedFulfillmentCount: concurrencyLimit)

        let postsCopy = posts
        Task {
            var postsSyncedToCloudCount = 0
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloudCount += 1
                        await postsSyncedToCloud.fulfill()
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
        
        await waitForExpectations([postsSyncedToCloud], timeout: networkTimeout)
        
        let localQueryForPosts = asyncExpectation(description: "Query for the post is successful")
        
        // query by predicate where title of the post is "title 25", should be successful for
        // only one query
        let predicate = Post.keys.id.eq(capturedPosts[25].id).and(Post.keys.title.eq(capturedPosts[25].title))
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                let queriedPosts = try await Amplify.DataStore.query(Post.self, where: predicate)
                XCTAssertNotNil(queriedPosts)
                XCTAssertEqual(queriedPosts.count, 1)
                XCTAssertEqual(capturedPosts[25].id, queriedPosts[0].id)
                XCTAssertEqual(capturedPosts[25].title, queriedPosts[0].title)
                XCTAssertEqual(capturedPosts[25].content, queriedPosts[0].content)
                await localQueryForPosts.fulfill()
            }
        }
        
        await waitForExpectations([localQueryForPosts], timeout: networkTimeout)
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
        try await startAmplifyAndWaitForSync()

        var posts = [Post]()
        for index in 0 ..< concurrencyLimit {
            let post = Post(title: "title \(index)",
                            content: "content",
                            createdAt: .now())
            posts.append(post)
        }
        let postsSyncedToCloud = asyncExpectation(description: "All posts saved and synced to cloud",
                                                  expectedFulfillmentCount: concurrencyLimit)

        let postsCopy = posts
        Task {
            var postsSyncedToCloudCount = 0
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    guard postsCopy.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
                       mutationEvent.version == 1 {
                        postsSyncedToCloudCount += 1
                        await postsSyncedToCloud.fulfill()
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
        await waitForExpectations([postsSyncedToCloud], timeout: networkTimeout)

        let postsDeletedLocally = asyncExpectation(description: "All posts deleted locally",
                                                   expectedFulfillmentCount: concurrencyLimit)

        let postsDeletedFromCloud = asyncExpectation(description: "All posts deleted and synced to cloud",
                                                     expectedFulfillmentCount: concurrencyLimit)
        
        Task {
            var postsDeletedFromCloudCount = 0
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    guard capturedPosts.contains(where: { $0.id == mutationEvent.modelId }) else {
                        return
                    }

                    if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                              mutationEvent.version == 1 {
                        await postsDeletedLocally.fulfill()
                    } else if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                              mutationEvent.version == 2 {
                        postsDeletedFromCloudCount += 1
                        await postsDeletedFromCloud.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        DispatchQueue.concurrentPerform(iterations: concurrencyLimit) { index in
            Task {
                try await Amplify.DataStore.delete(capturedPosts[index])
            }
        }
        
        await waitForExpectations([postsDeletedLocally, postsDeletedFromCloud], timeout: networkTimeout)
    }

    // MARK: - Helpers

    func validateSavePost() async throws {
        let date = Temporal.DateTime.now()
        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)
        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(newPost)
        
        await waitForExpectations(timeout: networkTimeout)
    }
    
    func stopDataStore() async throws {
        try await Amplify.DataStore.stop()
    }
    
    func clearDataStore() async throws {
        try await Amplify.DataStore.clear()
    }

    func startAmplify() throws {
        let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
            forResource: Self.amplifyConfigurationFile)
        do {
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail(String(describing: error))
        }
    }

    func startAmplifyAndWaitForSync() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.syncStarted)
    }

    func startAmplifyAndWaitForReady() async throws {
        try await startAmplifyAndWait(for: HubPayload.EventName.DataStore.ready)
    }

    private func startAmplifyAndWait(for eventName: String) async throws {
        let eventReceived = expectation(description: "DataStore \(eventName) event")

        var token: UnsubscribeToken!
        token = Amplify.Hub.listen(to: .dataStore,
                                   eventName: eventName) { _ in
            eventReceived.fulfill()
            Amplify.Hub.removeListener(token)
        }

        guard try await HubListenerTestUtilities.waitForListener(with: token, timeout: 5.0) else {
            XCTFail("Hub Listener not registered")
            return
        }

        try startAmplify()
        try await Amplify.DataStore.start()

        await waitForExpectations(timeout: 100.0)
    }

}
