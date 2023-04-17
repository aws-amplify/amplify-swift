//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
@available(iOS 13.0, *)
class DataStoreEndToEndTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    // swiftlint:disable:next cyclomatic_complexity
    func testCreate() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        var cancellables = Set<AnyCancellable>()
        let date = Temporal.DateTime.now()
        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        let saveSuccess = expectation(description: "save was successful.")
        let outboxMutationEnqueued = expectation(description: "received OutboxMutationEnqueuedEvent")
        let outboxIsNotEmptyReceived = expectation(description: "received outboxStatusReceived(false)")
        let outboxIsEmptyReceived = expectation(description: "received outboxStatusReceived(true)")
        let outboxMutationProcessed = expectation(description: "received outboxMutationProcessed")
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

        Amplify.DataStore.publisher(for: Post.self).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        } receiveValue: { mutationEvent in
            if mutationEvent.version == nil {
                localEventReceived.fulfill()
            } else if mutationEvent.version == 1 {
                remoteEventReceived.fulfill()
            }
        }.store(in: &cancellables)

        Amplify.DataStore.save(newPost) { result in
            switch result {
            case .success(let post):
                XCTAssertEqual(post.content, newPost.content)
                saveSuccess.fulfill()
            case .failure(let error):
                XCTFail("Failed to save post \(error)")
            }
        }

        wait(for: [saveSuccess,
                   outboxMutationEnqueued,
                   outboxIsNotEmptyReceived,
                   outboxIsEmptyReceived,
                   outboxMutationProcessed,
                   syncReceived,
                   localEventReceived,
                   remoteEventReceived], timeout: 10.0)
    }

    func testCreateMutateDelete() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        let date = Temporal.DateTime.now()

        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT from DataStoreEndToEndTests at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")
        let deleteReceived = expectation(description: "Delete notification received")

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

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)

        Amplify.DataStore.delete(updatedPost) { _ in }

        wait(for: [deleteReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - attempt to update the existing post with a condition that matches existing data
    /// - Then:
    ///    - the update with condition that matches existing data will be applied and returned.
    func testCreateThenMutateWithCondition() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

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
        let updateReceived = expectation(description: "Update notification received")

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

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost, where: post.title == title) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - update the post's content directly using `storageAdapter` to persist the update in local store
    ///    - save the post with the condition that matches the updated content, bypassing local store validation
    /// - Then:
    ///    - the post is first only updated on local store is not sync to the remote
    ///    - the save with condition reaches the remote and fails with conditional save failed
    func testCreateThenMutateWithConditionFailOnSync() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

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
        let updateLocalSuccess = expectation(description: "Update local successful")
        let conditionalReceived = expectation(description: "Conditional save failed received")

        let syncReceivedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.syncReceived)
        let conditionalSaveFailedFilter = HubFilters.forEventName(HubPayload.EventName.DataStore.conditionalSaveFailed)
        let filters = HubFilters.any(filters: syncReceivedFilter, conditionalSaveFailedFilter)
        let hubListener = Amplify.Hub.listen(to: .dataStore, isIncluded: filters) { payload in
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

            if payload.eventName == HubPayload.EventName.DataStore.syncReceived {
                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, newPost.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
            } else if payload.eventName == HubPayload.EventName.DataStore.conditionalSaveFailed {
                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.title, updatedPost.title)
                    XCTAssertEqual(mutationEvent.version, 1)
                    conditionalReceived.fulfill()
                    return
                }
            }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        storageAdapter.save(updatedPost) { result in
            switch result {
            case .success(let post):
                print("Saved post \(post)")
                updateLocalSuccess.fulfill()
            case .failure(let error):
                XCTFail("Failed to save post directly to local store \(error)")
            }
        }

        wait(for: [updateLocalSuccess], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost, where: post.content == updatedPost.content) { _ in }

        wait(for: [conditionalReceived], timeout: networkTimeout)
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
    func testStopStart() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()
        let stopStartSuccess = expectation(description: "stop then start successful")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        stopStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopStartSuccess], timeout: networkTimeout)
        try validateSavePost()

    }

    /// Ensure DataStore.stop followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has just configured, but not started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - Datastore should be started successfully
    ///
    func testConfigureAmplifyThenStopStart() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        let stopStartSuccess = expectation(description: "stop then start successful")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        stopStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopStartSuccess], timeout: networkTimeout)

    }

    /// Ensure DataStore.clear followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has just configured, but not started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - Datastore should be started successfully
    ///
    func testConfigureAmplifyThenClearStart() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        let clearStartSuccess = expectation(description: "clear then start successful")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        clearStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [clearStartSuccess], timeout: networkTimeout)

    }

    /// Ensure DataStore.stop followed by DataStore.start on a DispatchQueue
    ///  of a background thread is successful
    ///
    /// - Given:  DataStore has just configured, but not started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start on a background thread in the completion of the stop
    /// - Then:
    ///    - Datastore should be started successfully
    ///
    func testConfigureAmplifyThenStopStartonDispatch() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        let stopStartSuccess = expectation(description: "stop then start successful")
            Amplify.DataStore.stop { result in
                switch result {
                case .success:
                    DispatchQueue.global(qos: .background).async {
                        Amplify.DataStore.start { result in
                            switch result {
                            case .success:
                                stopStartSuccess.fulfill()
                            case .failure(let error):
                                XCTFail("\(error)")
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        wait(for: [stopStartSuccess], timeout: networkTimeout)

    }

    /// Ensure DataStore.clear followed by DataStore.start on a DispatchQueue
    /// of a background thread is successful
    ///
    /// - Given:  DataStore has just configured, but not started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start on a background thread in the completion of the stop
    /// - Then:
    ///    - Datastore should be started successfully
    ///
    func testConfigureAmplifyThenClearStartOnDispatch() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        let clearStartSuccess = expectation(description: "clear then start successful on DispatchQueue")
        DispatchQueue.global(qos: .background).async {
            Amplify.DataStore.clear { result in
                switch result {
                case .success:
                    DispatchQueue.global(qos: .background).async {
                        Amplify.DataStore.start { result in
                            switch result {
                            case .success:
                                clearStartSuccess.fulfill()
                            case .failure(let error):
                                XCTFail("\(error)")
                            }
                        }
                    }
                case .failure(let error):
                    XCTFail("\(error)")
                }
            }
        }
        wait(for: [clearStartSuccess], timeout: networkTimeout)

    }

    /// Ensure DataStore.start followed by DataStore.stop & restarting with
    /// DataStore.start is successful
    ///
    /// - Given:  DataStore has has just configured, but not started
    /// - When:
    ///    - DataStore.start
    ///    - DataStore.stop
    ///    - Followed by DataStore.start
    /// - Then:
    ///    - Datastore should be started successfully
    ///
    func testConfigureAmplifyThenStartStopStart() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        let startSuccess = expectation(description: "Start twice")
        startSuccess.expectedFulfillmentCount = 2
        let stopSuccess = expectation(description: "stop successful")

        Amplify.DataStore.start { result in
            switch result {
            case .success:
                startSuccess.fulfill()
                Amplify.DataStore.stop { result in
                    switch result {
                    case .success:
                        Amplify.DataStore.start { result in
                            switch result {
                            case .success:
                                startSuccess.fulfill()
                            case .failure(let error):
                                XCTFail("\(error)")
                            }
                        }
                        stopSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [startSuccess, stopSuccess], timeout: networkTimeout)

    }

    /// Ensure the DataStore is automatically started when querying for the first time
    ///
    /// - Given: DataStore is configured but not started
    /// - When:
    ///   - I call DataStore.query()
    /// - Then:
    ///   - DataStore is automatically started
    func testQueryImplicitlyStarts() throws {
        setUp(withModels: TestModelRegistration())
        let dataStoreStarted = expectation(description: "dataStoreStarted")
        let sink = Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in dataStoreStarted.fulfill() }

        try startAmplify()

        // We expect the query to complete, but not to return a value. Thus, we'll ignore the error
        let queryCompleted = expectation(description: "queryCompleted")
        Amplify.DataStore.query(Post.self, byId: "123") { _ in queryCompleted.fulfill() }

        wait(for: [dataStoreStarted, queryCompleted], timeout: networkTimeout)
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
    func testClearStart() throws {
        let startTime = Temporal.DateTime.now()
        let syncExpression = DataStoreSyncExpression(modelSchema: Post.schema) {
            Post.keys.createdAt >= startTime
        }
        setUp(
            withModels: TestModelRegistration(),
            dataStoreConfiguration: .custom(syncExpressions: [syncExpression])
        )

        try startAmplifyAndWaitForSync()
        let clearStartSuccess = expectation(description: "clear then start successful")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                Amplify.DataStore.start { result in
                    switch result {
                    case .success:
                        clearStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [clearStartSuccess], timeout: 10)
        try validateSavePost()
    }

    /// Perform concurrent saves and observe the data successfuly synced from cloud. Then delete the items afterwards
    /// and ensure they have successfully synced from cloud
    ///
    /// - Given: DataStore is in ready state
    /// - When:
    ///    - Concurrently perform Save's
    /// - Then:
    ///    - Ensure the expected mutation event with version 1 (synced from cloud) is received
    ///    - Clean up: Concurrently perform Delete's
    ///    - Ensure the expected mutation event with version 2 (synced from cloud) is received
    ///
    func testConcurrentSave() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        var posts = [Post]()
        let count = 2
        for index in 0 ..< count {
            let post = Post(title: "title \(index)",
                            content: "content",
                            createdAt: .now())
            posts.append(post)
        }
        let postsSyncedToCloud = expectation(description: "All posts saved and synced to cloud")
        postsSyncedToCloud.expectedFulfillmentCount = count
        var postsSyncedToCloudCount = 0

        let postsDeletedLocally = expectation(description: "All posts deleted locally")
        postsDeletedLocally.expectedFulfillmentCount = count

        let postsDeletedFromCloud = expectation(description: "All posts deleted and synced to cloud")
        postsDeletedFromCloud.expectedFulfillmentCount = count
        var postsDeletedFromCloudCount = 0

        log.debug("Created posts: [\(posts.map { $0.identifier })]")

        let sink = Amplify.DataStore.publisher(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { mutationEvent in
            guard posts.contains(where: { $0.id == mutationEvent.modelId }) else {
                return
            }

            if mutationEvent.mutationType == MutationEvent.MutationType.create.rawValue,
               mutationEvent.version == 1 {
                postsSyncedToCloudCount += 1
                self.log.debug("Post saved and synced from cloud \(mutationEvent.modelId) \(postsSyncedToCloudCount)")
                postsSyncedToCloud.fulfill()
            } else if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                      mutationEvent.version == 1 {
                self.log.debug(
                    "Post deleted locally \(mutationEvent.modelId)")
                postsDeletedLocally.fulfill()
            } else if mutationEvent.mutationType == MutationEvent.MutationType.delete.rawValue,
                      mutationEvent.version == 2 {
                postsDeletedFromCloudCount += 1
                self.log.debug(
                    "Post deleted and synced from cloud \(mutationEvent.modelId) \(postsDeletedFromCloudCount)")
                postsDeletedFromCloud.fulfill()
            }
        }

        DispatchQueue.concurrentPerform(iterations: count) { index in
            self.log.debug("save \(index)")
            Amplify.DataStore.save(posts[index]) { _ in }
        }

        wait(for: [postsSyncedToCloud], timeout: 100)

        DispatchQueue.concurrentPerform(iterations: count) { index in
            self.log.debug("delete \(index)")
            Amplify.DataStore.delete(posts[index]) { _ in }
        }
        wait(for: [postsDeletedLocally, postsDeletedFromCloud], timeout: 100)
        sink.cancel()
    }

    /// Create model instances for different models but same primary key value
    ///
    /// Given - DataStore with clean state
    /// When
    ///     - create post and comment with the same random id
    /// Then
    ///     - all instances should be created successfully with the same id
    func testCreateModelInstances_withSamePrimaryKeyForDifferentModels_allSucceed() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        let uuid = UUID().uuidString
        let newPost = Post(
            id: uuid,
            title: UUID().uuidString,
            content: UUID().uuidString,
            createdAt: .now()
        )

        let postCreateExpectation = expectation(description: "Post is created")
        var createdPost: Post?
        Amplify.DataStore.save(newPost) { result in
            defer { postCreateExpectation.fulfill() }
            if case .success(let post) = result {
                createdPost = post
            }
        }
        let newComment = Comment(
            id: uuid,
            content: UUID().uuidString,
            createdAt: .now(),
            post: newPost
        )
        var createdComment: Comment?
        let commentCreateExpectation = expectation(description: "Comment is created")
        Amplify.DataStore.save(newComment) { result in
            defer { commentCreateExpectation.fulfill() }
            if case .success(let comment) = result {
                createdComment = comment
            }
        }
        wait(for: [postCreateExpectation, commentCreateExpectation], timeout: 5)

        XCTAssertNotNil(createdPost)
        XCTAssertNotNil(createdComment)
        XCTAssertEqual(createdPost?.id, createdComment?.id)
    }

    ///
    /// - Given: DataStore with clean state
    /// - When:
    ///     - do some mutaions to ensure MutationEventPublisher works fine
    ///     - wait 1 second for OutgoingMutationQueue stateMachine transform to waitingForEventToProcess state
    ///     - do some mutations in parallel
    /// - Then: verify no mutaiton loss
    func testParallelMutations_whenWaitingForEventToProcess_noMutationLoss() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        let parallelSize = 100
        let initExpectation = expectation(description: "expect MutationEventPublisher works fine")
        let parallelExpectation = expectation(description: "expect parallel processing no data loss")

        let newPost = Post(title: UUID().uuidString, content: UUID().uuidString, createdAt: .now())

        let titlePrefix = UUID().uuidString
        let posts = (0 ..< parallelSize).map {
            Post(title: "\(titlePrefix)-\($0)", content: UUID().uuidString, createdAt: .now())
        }
        var expectedResult = Set<String>()
        let cancellable = Amplify.Hub.publisher(for: .dataStore)
            .sink { payload in
                let event = DataStoreHubEvent(payload: payload)
                switch event {
                case .outboxMutationProcessed(let mutationEvent):
                    guard mutationEvent.modelName == Post.modelName,
                          let post = mutationEvent.element.model as? Post
                    else { break }

                    if post.title == newPost.title {
                        initExpectation.fulfill()
                    }

                    if post.title.hasPrefix(titlePrefix) {
                        expectedResult.insert(post.title)
                    }

                    if expectedResult.count == parallelSize {
                        parallelExpectation.fulfill()
                    }
                default: break
                }
            }
        _ = Amplify.DataStore.save(newPost)
        wait(for: [initExpectation], timeout: 5)
        wait(for: 1)

        for post in posts {
            _ = Amplify.DataStore.save(post)
        }

        wait(for: [parallelExpectation], timeout: Double(parallelSize))
        cancellable.cancel()
        XCTAssertEqual(expectedResult, Set(posts.map(\.title)))
    }

    func testStop_whenSavingInProgress() throws {
        let startTime = Temporal.DateTime.now()
        let syncExpression = DataStoreSyncExpression(modelSchema: Post.schema) {
            Post.keys.createdAt >= startTime
        }
        setUp(
            withModels: TestModelRegistration(),
            dataStoreConfiguration: .custom(syncExpressions: [syncExpression])
        )
        try startAmplifyAndWaitForSync()

        let postCount = 1_000
        let posts = (0 ..< postCount).map { _ in
            Post(title: UUID().uuidString, content: UUID().uuidString, createdAt: .now())
        }

        let saveFinished = expectation(description: "Posts are saved")
        saveFinished.expectedFulfillmentCount = postCount
        let stopped = expectation(description: "DataStore plugin stopped")

        let queryLocalFinished = expectation(description: "Query local finished")
        queryLocalFinished.expectedFulfillmentCount = postCount

        for post in posts {
            Task {
                try await sleepMill(UInt64.random(in: 50 ..< 150))
                Amplify.DataStore.save(post) { result in
                    defer { saveFinished.fulfill() }
                    if case .success(let savedPost) = result {
                        XCTAssertEqual(post, savedPost)
                    }
                }
            }
        }

        Task {
            try await sleepMill(100)
            Amplify.DataStore.stop { _ in
                stopped.fulfill()
            }
        }

        wait(for: [saveFinished, stopped], timeout: 30)

        var localSuccess = 0
        for post in posts {
            Amplify.DataStore.query(Post.self, byId: post.id) { result in
                defer { queryLocalFinished.fulfill() }
                if case .success(let savedPost) = result {
                    XCTAssertEqual(post, savedPost)
                    localSuccess += 1
                }
            }
        }
        wait(for: [queryLocalFinished], timeout: 30)
        XCTAssertEqual(localSuccess, postCount)
    }

    // MARK: - Helpers
    private func sleepMill(_ milliseconds: UInt64) async throws {
        try await Task.sleep(nanoseconds: milliseconds * NSEC_PER_MSEC)
    }

    func validateSavePost() throws {
        let date = Temporal.DateTime.now()
        let newPost = Post(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)
        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived
        ) { payload in
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

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }
        wait(for: [createReceived], timeout: 10)
    }
}

@available(iOS 13.0, *)
extension DataStoreEndToEndTests: DefaultLogger {

} // swiftlint:disable:this file_length
