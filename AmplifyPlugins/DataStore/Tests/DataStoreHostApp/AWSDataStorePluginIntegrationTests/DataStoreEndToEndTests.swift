//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AWSDataStorePlugin
@testable import DataStoreHostApp

class DataStoreEndToEndTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    func testSetUp() async throws {
        do {
            await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
            try await startAmplifyAndWaitForSync()
        } catch {
            XCTFail("Error \(error)")
        }
    }
    
    func testCreate() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        var cancellables = Set<AnyCancellable>()
        let date = Temporal.DateTime.now()
        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        let outboxMutationEnqueued = expectation(description: "received OutboxMutationEnqueuedEvent")
        outboxMutationEnqueued.assertForOverFulfill = false
        let outboxIsNotEmptyReceived = expectation(description: "received outboxStatusReceived(false)")
        outboxIsNotEmptyReceived.assertForOverFulfill = false
        let outboxIsEmptyReceived = expectation(description: "received outboxStatusReceived(true)")
        outboxIsEmptyReceived.assertForOverFulfill = false
        let outboxMutationProcessed = expectation(description: "received outboxMutationProcessed")
        outboxMutationProcessed.assertForOverFulfill = false
        let syncReceived = expectation(description: "SyncReceived(MutationEvent(version: 1))")
        let localEventReceived = expectation(description: "received mutation event with version nil")
        let remoteEventReceived = expectation(description: "received mutation event with version 1")
        Amplify.Hub.publisher(for: .dataStore)
            .sink { payload in
                let event = DataStoreHubEvent(payload: payload)
                switch event {
                case .outboxMutationEnqueued:
                    outboxMutationEnqueued.fulfill()
                case .outboxStatus(let status):
                    if !status.isEmpty {
                        outboxIsNotEmptyReceived.fulfill()
                    } else {
                        outboxIsEmptyReceived.fulfill()
                    }
                case .outboxMutationProcessed:
                    outboxMutationProcessed.fulfill()
                case .syncReceived(let mutationEvent):
                    guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                        return
                    }
                    if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                        XCTAssertEqual(post.content, newPost.content)
                        XCTAssertEqual(mutationEvent.version, 1)
                        syncReceived.fulfill()
                        return
                    }
                default:
                    break
                }
            }.store(in: &cancellables)

        let task = Task {
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.version == nil {
                        localEventReceived.fulfill()
                    } else if mutationEvent.version == 1 {
                        remoteEventReceived.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }

        let savedPost = try await Amplify.DataStore.save(newPost)
        XCTAssertEqual(savedPost.content, newPost.content)
        await waitForExpectations(timeout: 10.0)
    }

    func testCreateMutateDelete() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let date = Temporal.DateTime.now()

        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        var hubListener = Amplify.Hub.listen(
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

        let updateReceived = expectation(description: "Update notification received")
        hubListener = Amplify.Hub.listen(
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

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(updatedPost)
        await waitForExpectations(timeout: networkTimeout)
        
        let deleteReceived = expectation(description: "Delete notification received")
        hubListener = Amplify.Hub.listen(
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

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                    return
                }
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        try await Amplify.DataStore.delete(updatedPost)
        await waitForExpectations(timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - attempt to update the existing post with a condition that matches existing data
    /// - Then:
    ///    - the update with condition that matches existing data will be applied and returned.
    func testCreateThenMutateWithCondition() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        let post = Post.keys
        let date = Temporal.DateTime.now()
        let title = "This is a new post I created"
        let newPost = Post(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)
        var updatedPost = newPost
            updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        var hubListener = Amplify.Hub.listen(
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
        
        let updateReceived = expectation(description: "Update notification received")
        hubListener = Amplify.Hub.listen(
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

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        _ = try await Amplify.DataStore.save(updatedPost, where: post.title == title)
        await waitForExpectations(timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - update the post's content directly using `storageAdapter` to persist the update in local store
    ///    - save the post with the condition that matches the updated content, bypassing local store validation
    /// - Then:
    ///    - the post is first only updated on local store is not sync to the remote
    ///    - the save with condition reaches the remote and fails with conditional save failed
    func testCreateThenMutateWithConditionFailOnSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let post = Post.keys
        let date = Temporal.DateTime.now()
        let title = "This is a new post I created"
        let newPost = Post(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date.iso8601String)",
            createdAt: date)

        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let syncReceivedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncReceived)
        let conditionalSaveFailedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.conditionalSaveFailed)
        let filters = HubFilters.any(filters: syncReceivedFilter, conditionalSaveFailedFilter)
        var hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filters) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            // This check is to protect against stray events being processed after the test has completed,
            // and it shouldn't be construed as a pattern necessary for production applications.
            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if payload.eventName == HubPayload.EventName.DataStore.syncReceived {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
            }
        }

        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        _ = try await Amplify.DataStore.save(newPost)
        await waitForExpectations(timeout: networkTimeout)
        
        let updateLocalSuccess = expectation(description: "Update local successful")
        let result = storageAdapter.save(updatedPost, modelSchema: updatedPost.schema, condition: nil, eagerLoad: true)
        switch result {
        case .success(let post):
            print("Saved post \(post)")
            updateLocalSuccess.fulfill()
        case .failure(let error):
            XCTFail("Failed to save post directly to local store \(error)")
        }

        await waitForExpectations(timeout: networkTimeout)

        let conditionalReceived = expectation(description: "Conditional save failed received")
        hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filters) { payload in
            guard let mutationEvent = payload.data as? MutationEvent else {
                XCTFail("Can't cast payload as mutation event")
                return
            }

            // This check is to protect against stray events being processed after the test has completed,
            // and it shouldn't be construed as a pattern necessary for production applications.
            guard let post = try? mutationEvent.decodeModel() as? Post, post.id == newPost.id else {
                return
            }

            if payload.eventName == HubPayload.EventName.DataStore.conditionalSaveFailed {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.title, updatedPost.title)
                    XCTAssertEqual(mutationEvent.version, 1)
                    conditionalReceived.fulfill()
                    return
                }
            }
        }
        guard try await HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        
        _ = try await Amplify.DataStore.save(updatedPost, where: post.content == updatedPost.content)

        await waitForExpectations(timeout: networkTimeout)
    }

    /// Ensure DataStore.stop followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testStopStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        try await Amplify.DataStore.stop()
        try await Amplify.DataStore.start()
        try await validateSavePost()
    }
    
    /// Ensure DataStore.stop followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has just configured, but not yet started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - DataStore should be successfully started
    func testConfigureAmplifyThenStopStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        try await Amplify.DataStore.stop()
        try await Amplify.DataStore.start()
    }

    /// Ensure the DataStore is automatically started when querying for the first time
    ///
    /// - Given: DataStore is configured but not started
    /// - When:
    ///   - I call DataStore.query()
    /// - Then:
    ///   - DataStore is automatically started
    func testQueryImplicitlyStarts() async throws {
        await setUp(withModels: TestModelRegistration())
        let dataStoreStarted = expectation(description: "dataStoreStarted")
        let sink = Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in dataStoreStarted.fulfill() }

        try startAmplify()

        // We expect the query to complete, but not to return a value. Thus, we'll ignore the error
        _ = try await Amplify.DataStore.query(Post.self, byId: "123")

        await waitForExpectations(timeout: networkTimeout)
        sink.cancel()
    }

    /// Ensure DataStore.clear followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start in the completion of the clear
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testClearStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
        try await Amplify.DataStore.clear()
        try await Amplify.DataStore.start()
        try await validateSavePost()
        try await validateSavePost()
    }

    /// Ensure DataStore.clear followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has just configured, but not yet started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start in the completion of the clear
    /// - Then:
    ///    - DataStore should be successfully started
    func testConfigureAmplifyThenClearStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        try await Amplify.DataStore.clear()
        try await Amplify.DataStore.start()
    }

    /// Create model instances for different models but same primary key value
    ///
    /// Given - DataStore with clean state
    /// When
    ///     - create post and comment with the same random id
    /// Then
    ///     - all instances should be created successfully with the same id
    func testCreateModelInstances_withSamePrimaryKeyForDifferentModels_allSucceed() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let uuid = UUID().uuidString
        let newPost = Post(
            id: uuid,
            title: UUID().uuidString,
            content: UUID().uuidString,
            createdAt: .now()
        )

        let createdPost = try await Amplify.DataStore.save(newPost)
        let newComment = Comment(
            id: uuid,
            content: UUID().uuidString,
            createdAt: .now(),
            post: newPost
        )
        let createdComment = try await Amplify.DataStore.save(newComment)

        XCTAssertEqual(createdPost.id, createdComment.id)
    }

    ///
    /// - Given: DataStore with clean state
    /// - When:
    ///     - do some mutaions to ensure MutationEventPublisher works fine
    ///     - wait 1 second for OutgoingMutationQueue stateMachine transform to waitingForEventToProcess state
    ///     - do some mutations in parallel
    /// - Then: verify no mutaiton loss
    func testParallelMutations_whenWaitingForEventToProcess_noMutationLoss() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()

        let parallelSize = 100
        let initExpectation = asyncExpectation(description: "expect MutationEventPublisher works fine")
        let parallelExpectation = asyncExpectation(description: "expect parallel processing no data loss")

        let newPost = Post(title: UUID().uuidString, content: UUID().uuidString, createdAt: .now())

        let titlePrefix = UUID().uuidString
        let posts = (0..<parallelSize).map { Post(title: "\(titlePrefix)-\($0)", content: UUID().uuidString, createdAt: .now()) }
        var expectedResult = Set<String>()
        let extractPost: (DataStoreHubEvent) -> Post? = {
            if case .outboxMutationProcessed(let mutationEvent) = $0,
               mutationEvent.modelName == Post.modelName
            {
                return mutationEvent.element.model as? Post
            }
            return nil
        }

        let cancellable = Amplify.Hub.publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.outboxMutationProcessed }
            .map { DataStoreHubEvent(payload: $0) }
            .compactMap(extractPost)
            .sink { post in
                if post.title == newPost.title {
                    Task { await initExpectation.fulfill() }
                }

                if post.title.hasPrefix(titlePrefix) {
                    expectedResult.insert(post.title)
                }

                if expectedResult.count == parallelSize {
                    Task { await parallelExpectation.fulfill() }
                }
            }
        try await Amplify.DataStore.save(newPost)
        await AsyncTesting.waitForExpectations([initExpectation], timeout: 10)
        try await Task.sleep(seconds: 1)

        for post in posts {
            Task {
                try? await Amplify.DataStore.save(post)
            }
        }
        await AsyncTesting.waitForExpectations([parallelExpectation], timeout: Double(parallelSize))
        cancellable.cancel()
        XCTAssertEqual(expectedResult, Set(posts.map(\.title)))
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
}

extension DataStoreEndToEndTests: DefaultLogger {

}
