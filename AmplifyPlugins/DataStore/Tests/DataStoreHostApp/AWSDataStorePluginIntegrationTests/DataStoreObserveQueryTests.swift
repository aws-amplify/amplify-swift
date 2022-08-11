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

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class DataStoreObserveQueryTests: SyncEngineIntegrationTestBase {

    var cancellables = Set<AnyCancellable>()
    
    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: Post.self)
            registry.register(modelType: Comment.self)
        }

        let version: String = "1"
    }

    /// ObserveQuery API will eventually return query snapshot with `isSynced` true
    ///
    /// - Given: DataStore is cleared
    /// - When:
    ///    - ObserveQuery API is called to start the sync engine
    /// - Then:
    ///    - The first snapshot should have `isSynced` false
    ///    - Eventually one of the query snapshots will be returned with `isSynced` true
    ///
    func testObserveQueryInitialSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        await clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        snapshotWithIsSynced.assertForOverFulfill = false
        Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshots.append(querySnapshot)
            if querySnapshot.isSynced {
                snapshotWithIsSynced.fulfill()
            }
        }.store(in: &cancellables)
        let receivedPost = expectation(description: "received Post")
        try await savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()),
                                     postSyncedExpctation: receivedPost)
        await waitForExpectations(timeout: 100)

        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
    }

    /// Apply a query predicate "title begins with 'xyz'"
    ///
    /// - Given: DataStore is set up with an empty local store
    /// - When:
    ///    - ObserveQuery is called with a predicate
    /// - Then:
    ///    - The models only contain models based on the predicate
    ///
    func testInitialSyncWithPredicate() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .info)
        try startAmplify()
        try await savePostAndWaitForSync(Post(title: "xyz 1", content: "content", createdAt: .now()))
        try await savePostAndWaitForSync(Post(title: "xyz 2", content: "content", createdAt: .now()))
        try await savePostAndWaitForSync(Post(title: "xyz 3", content: "content", createdAt: .now()))
        await clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        snapshotWithIsSynced.assertForOverFulfill = false
        var snapshotWithIsSyncedFulfilled = false
        let predicate = Post.keys.title.beginsWith("xyz")
        Amplify.DataStore.observeQuery(for: Post.self, where: predicate).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if !snapshotWithIsSyncedFulfilled {
                snapshots.append(querySnapshot)

                if querySnapshot.isSynced {
                    snapshotWithIsSyncedFulfilled = true
                    snapshotWithIsSynced.fulfill()
                }
            }
        }.store(in: &cancellables)

        let receivedPost = expectation(description: "received Post")
        try await savePostAndWaitForSync(Post(title: "xyz", content: "content", createdAt: .now()),
                                     postSyncedExpctation: receivedPost)
        await waitForExpectations(timeout: 100)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        log.info("\(snapshots)")
    }

    /// Apply a sort order. A query snapshot with the recently saved post should be the last item when
    /// sort order is provided as ascending `createdAt`
    ///
    /// - Given: DataStore is set up with empty local store
    /// - When:
    ///    - ObserveQuery is called
    /// - Then:
    ///    - Each snapshot should have items sorted according to the sort order
    ///
    func testObserveQueryWithSort() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        await clearDataStore()
        let post1 = Post(title: "title", content: "content", createdAt: .now())
        let post2 = Post(title: "title", content: "content", createdAt: .now().add(value: 1, to: .second))
        let snapshotWithSavedPost = expectation(description: "query snapshot with saved post")
        snapshotWithSavedPost.assertForOverFulfill = false
        Amplify.DataStore.observeQuery(for: Post.self,
                                       sort: .ascending(Post.keys.createdAt))
        .sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if querySnapshot.items.contains(where: { model in
                model.id == post2.id
            }) {
                var items = querySnapshot.items
                let actualPost2 = items.removeLast()
                let actualPost1 = items.removeLast()
                XCTAssertEqual(actualPost2.id, post2.id)
                XCTAssertEqual(actualPost1.id, post1.id)
                snapshotWithSavedPost.fulfill()
            }
        }.store(in: &cancellables)

        let receivedPost1 = expectation(description: "received Post")
        try await savePostAndWaitForSync(post1, postSyncedExpctation: receivedPost1)
        let receivedPost2 = expectation(description: "received Post")
        try await savePostAndWaitForSync(post2, postSyncedExpctation: receivedPost2)
        await waitForExpectations(timeout: 100)
    }

    /// ObserveQuery with DataStore delta sync. Ensure datastore has synced the models and stopped.
    /// When ObserveQuery is called, it will start DataStore and perform a delta sync.
    ///
    /// - Given: DataStore has already synced the models to local store. DataStore is then stopped.
    /// - When:
    ///    - ObserveQuery is called to perform a delta sync
    /// - Then:
    ///    - The first snapshot should have the old data and `isSynced` false
    ///    - The final snapshot should have all the models with `isSynced` true
    ///
    func testObserveQueryWithDataStoreDeltaSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        try await savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()))
        let numberOfPosts = await queryNumberOfPosts()
        XCTAssertTrue(numberOfPosts > 0)
        await stopDataStore()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        snapshotWithIsSynced.assertForOverFulfill = false
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshots.append(querySnapshot)
            if querySnapshot.isSynced {
                snapshotWithIsSynced.fulfill()
            }
        }.store(in: &cancellables)
        let receivedPost = expectation(description: "received Post")
        try await savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()),
                                     postSyncedExpctation: receivedPost)
        await waitForExpectations(timeout: 100)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        XCTAssertTrue(snapshots.last!.isSynced)
        XCTAssertTrue(snapshots.last!.items.count > numberOfPosts)
    }

    /// ObserveQuery is set up with a query predicate.
    /// Sync is completed and actions are applied after sync to observe expected snapshots.
    ///
    /// - Given: DataStore has already synced the models to local store. ObserveQuery is started with a predicate
    /// - When/Then:
    ///     - Add at least one model that matches the given predicate. Model is received on the snapshot.
    ///     - Add at least one model that does NOT match the given predicate. Model is not received on the snapshot
    ///     - Update a model that matches the given predicate so that it no longer matches the predicate.
    ///         Model is removed from the snapshot.
    ///     - Update a model that does NOT match the predicate so that it now matches the predicate.
    ///         Model is added to the snapshot
    ///     - Delete a model that matches the predicate. Model is removed from the snapshot
    ///     - Delete a model that does NOT match the predicate. No snapshot is emitted
    func testPredicateWithCreateUpdateDelete() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .verbose)
        try startAmplify()
        let testId = UUID().uuidString
        var snapshotCount = 0
        let predicate = Post.keys.title.beginsWith("xyz") && Post.keys.content == testId
        let snapshotExpectation1 = expectation(description: "received snapshot 1")
        var onSnapshot: ((DataStoreQuerySnapshot<Post>) -> Void) = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 1 {
                self.log.info("1. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation1.fulfill()
            }
        }
        Amplify.DataStore.observeQuery(for: Post.self, where: predicate).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { onSnapshot($0) }.store(in: &cancellables)
        await waitForExpectations(timeout: 10)
        
        // (1) Add model that matches predicate - should be received on the snapshot
        let postMatchPredicate = Post(title: "xyz 1", content: testId, createdAt: .now())
        let snapshotExpectation23 = expectation(description: "received snapshot 2 / 3")
        snapshotExpectation23.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 2 || snapshotCount == 3 {
                // See (1), subsequent snapshot should have item with "xyz 1".
                self.log.info("2/3. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 1")
                snapshotExpectation23.fulfill()
            }
        }
        try await savePostAndWaitForSync(postMatchPredicate)

        // (2) Add model that does not match predicate - should not be received on the snapshot
        // (3) Update model that used to match the predicate to no longer match - should be removed from snapshot
        let postDoesNotMatch = Post(title: "doesNotMatch", content: testId, createdAt: .now())
        let snapshotExpectation4 = expectation(description: "received snapshot 4")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 4 {
                // See (2), should not be added to the snapshot.
                // See (3), should be removed from the snapshot. So the resulting snapshot is empty.
                self.log.info("4. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation4.fulfill()
            }
        }
        let postDoesNotMatchExpectation = expectation(description: "received postDoesNotMatchExpectation")
        try await savePostAndWaitForSync(postDoesNotMatch, postSyncedExpctation: postDoesNotMatchExpectation)
        var postMatchPredicateNoLongerMatches = postMatchPredicate
        postMatchPredicateNoLongerMatches.title = "doesNotMatch"
        try await savePostAndWaitForSync(postMatchPredicateNoLongerMatches)


        // (4) Update model that does not match predicate to match - should be added to snapshot
        let snapshotExpectation56 = expectation(description: "received snapshot 5 / 6")
        snapshotExpectation56.expectedFulfillmentCount = 2
        var postDoesNotMatchNowMatches = postDoesNotMatch
        postDoesNotMatchNowMatches.title = "xyz 2"
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 5 || snapshotCount == 6 {
                // See (4). the post that now matches the snapshot should be added
                self.log.info("5/6. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 2")
                snapshotExpectation56.fulfill()
            }
        }
        try await savePostAndWaitForSync(postDoesNotMatchNowMatches)

        // (5) Delete the model that matches the predicate - should be removed
        let snapshotExpectation7 = expectation(description: "received snapshot 7")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 7 {
                // See (5). the post that matched the predicate was deleted
                self.log.info("7. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation7.fulfill()
            }
        }
        try await deletePostAndWaitForSync(postDoesNotMatchNowMatches)

        // (6) Delete the model that does not match predicate - should have no snapshot emitted
        let snapshotExpectation8 = expectation(description: "received snapshot 8")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 8 {
                // See (6). Snapshot that is emitted due to "xyz 3" should not contain the deleted model
                self.log.info("8. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 3")
                snapshotExpectation8.fulfill()
            }
        }
        let postMatchPredicateNoLongerMatchesExpectation = expectation(description: " received")
        try await deletePostAndWaitForSync(postMatchPredicateNoLongerMatches,
                                       postSyncedExpctation: postMatchPredicateNoLongerMatchesExpectation)
        // Save "xyz 3" to force a snapshot to be emitted
        try await savePostAndWaitForSync(Post(title: "xyz 3", content: testId, createdAt: .now()))
    }

    /// ObserveQuery is set up with a sort order.
    /// Sync is completed and actions are applied after sync to observe expected snapshots.
    ///
    /// - Given: DataStore has already synced the models to local store. ObserveQuery is started with a sort order
    /// - When/Then:
    ///    - Add several models with unique values for the field that is sorted on.
    ///      The snapshot should have the models in the correct sorted order
    ///    - Update models, modifying the field that is sorted on.
    ///      The snasphot sould have the models in the correct sorted order
    ///    - Delete models. The snapshot should have the models removed
    ///
    func testSortWithCreateUpdateDelete() async throws {
        await setUp(withModels: TestModelRegistration(), logLevel: .info)
        try startAmplify()

        let testId = UUID().uuidString
        var snapshotCount = 0
        let snapshotExpectation1 = expectation(description: "received snapshot 1")
        var onSnapshot: ((DataStoreQuerySnapshot<Post>) -> Void) = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 1 {
                XCTAssertEqual(items.count, 0)
                snapshotExpectation1.fulfill()
            }
        }
        Amplify.DataStore.observeQuery(for: Post.self,
                                       where: Post.keys.content == testId,
                                       sort: .ascending(Post.keys.title))
        .sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { onSnapshot($0) }.store(in: &cancellables)
        await waitForExpectations(timeout: 10)

        // (1) Add several models
        let snapshotExpectation23 = expectation(description: "received snapshot 2 / 3")
        snapshotExpectation23.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 2 || snapshotCount == 3 {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "a")
                snapshotExpectation23.fulfill()
            }
        }
        let postA = Post(title: "a", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postA)

        let snapshotExpectation45 = expectation(description: "received snapshot 4 / 5")
        snapshotExpectation45.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 4 || snapshotCount == 5 {
                XCTAssertEqual(items.count, 2)
                XCTAssertEqual(items[0].title, "a")
                XCTAssertEqual(items[1].title, "m")
                snapshotExpectation45.fulfill()
            }
        }
        let postM = Post(title: "m", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postM)

        let snapshotExpectation67 = expectation(description: "received snapshot 6 / 7")
        snapshotExpectation67.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 6 || snapshotCount == 7 {
                XCTAssertEqual(items.count, 3)
                XCTAssertEqual(items[0].title, "a")
                XCTAssertEqual(items[1].title, "m")
                XCTAssertEqual(items[2].title, "z")
                snapshotExpectation67.fulfill()
            }
        }
        let postZ = Post(title: "z", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postZ)

        // (2) Update models to move them into different orders
        let snapshotExpectation89 = expectation(description: "received snapshot 8 / 9")
        snapshotExpectation89.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 8 || snapshotCount == 9 {
                XCTAssertEqual(items.count, 3)
                XCTAssertEqual(items[0].title, "m")
                XCTAssertEqual(items[1].title, "n")
                XCTAssertEqual(items[2].title, "z")
                snapshotExpectation89.fulfill()
            }
        }
        var postNFromA = postA
        postNFromA.title = "n"
        try await savePostAndWaitForSync(postNFromA)
        
        let snapshotExpectation1011 = expectation(description: "received snapshot 10 / 11")
        snapshotExpectation1011.expectedFulfillmentCount = 2
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 10 || snapshotCount == 11 {
                XCTAssertEqual(items.count, 3)
                XCTAssertEqual(items[0].title, "b")
                XCTAssertEqual(items[1].title, "m")
                XCTAssertEqual(items[2].title, "n")
                snapshotExpectation1011.fulfill()
            }
        }
        var postBFromZ = postZ
        postBFromZ.title = "b"
        try await savePostAndWaitForSync(postBFromZ)

        // (3) Delete models
        let snapshotExpectation12 = expectation(description: "received snapshot 12")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 12 {
                XCTAssertEqual(items.count, 2)
                XCTAssertEqual(items[0].title, "b")
                XCTAssertEqual(items[1].title, "n")
                snapshotExpectation12.fulfill()
            }
        }
        try await deletePostAndWaitForSync(postM)
        
        let snapshotExpectation13 = expectation(description: "received snapshot 13")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 13 {
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "b")
                snapshotExpectation13.fulfill()
            }
        }
        try await deletePostAndWaitForSync(postNFromA)
        
        let snapshotExpectation14 = expectation(description: "received snapshot 13")
        onSnapshot = { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 14 {
                XCTAssertEqual(items.count, 0)
                snapshotExpectation14.fulfill()
            }
        }
        try await deletePostAndWaitForSync(postBFromZ)
    }

    /// Ensure stopping datastore will not complete the observeQuery subscribers.
    ///
    /// - Given: DataStore is ready, first snapshot received.
    /// - When:
    ///    - DataStore.stop
    /// - Then:
    ///    -  ObserveQuery is not completed.
    ///
    func testObserveQueryShouldResetOnDataStoreStop() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let firstSnapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var onComplete: ((Subscribers.Completion<DataStoreError>) -> Void) = { _ in }
        Amplify.DataStore.observeQuery(for: Post.self).sink { onComplete($0) } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                firstSnapshotWithIsSynced.fulfill()
            }
        }.store(in: &cancellables)
        await waitForExpectations(timeout: 100)
        
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        onComplete = { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        let stopCompleted = expectation(description: "DataStore stop completed")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                stopCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        await waitForExpectations(timeout: 10)
    }

    /// Ensure clearing datastore will not complete the observeQuery subscribers.
    ///
    /// - Given: DataStore is ready, first snapshot received.
    /// - When:
    ///    - DataStore.clear
    /// - Then:
    ///    -  ObserveQuery is not completed.
    ///
    func testObserveQueryShouldResetOnDataStoreClear() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let firstSnapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var onComplete: ((Subscribers.Completion<DataStoreError>) -> Void) = { _ in }
        Amplify.DataStore.observeQuery(for: Post.self).sink { onComplete($0) } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                firstSnapshotWithIsSynced.fulfill()
            }
        }.store(in: &cancellables)
        await waitForExpectations(timeout: 100)
        
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        onComplete = { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        let clearCompleted = expectation(description: "DataStore clear completed")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                clearCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        await waitForExpectations(timeout: 10)
    }

    func testObserveQueryShouldStartOnDataStoreStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let firstSnapshot = expectation(description: "first query snapshot")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        var onComplete: ((Subscribers.Completion<DataStoreError>) -> Void) = { _ in }
        var onSnapshot: ((DataStoreQuerySnapshot<Post>) -> Void) = { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            }
        }
        Amplify.DataStore.observeQuery(for: Post.self).sink { onComplete($0) } receiveValue: { onSnapshot($0) }
            .store(in: &cancellables)
        await waitForExpectations(timeout: 100)
        
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        onComplete = { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        let stopCompleted = expectation(description: "DataStore stop completed")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                stopCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        await waitForExpectations(timeout: 10)
        
        let observeQueryReceivedCompleted2 = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted2.isInverted = true
        onComplete = { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted2.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        let secondSnapshot = expectation(description: "second query snapshot")
        onSnapshot = { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            }
        }
        let startCompleted = expectation(description: "DataStore start completed")
        Amplify.DataStore.start { result in
            switch result {
            case .success:
                startCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        await waitForExpectations(timeout: 10)
    }

    // MARK: - Helpers

    func savePostAndWaitForSync(_ post: Post, postSyncedExpctation: XCTestExpectation? = nil) async throws {
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation saved to the local store
        // and the second event due to the subscription event received from the remote store)
        let receivedPost = postSyncedExpctation ?? expectation(description: "received Post")
        receivedPost.expectedFulfillmentCount = 2
        receivedPost.assertForOverFulfill = false
        Amplify.DataStore.publisher(for: Post.self).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { mutationEvent in
            if mutationEvent.modelId == post.id {
                receivedPost.fulfill()
            }
        }.store(in: &cancellables)
        
        _ = try await Amplify.DataStore.save(post)
        if postSyncedExpctation == nil {
            await waitForExpectations(timeout: 100)
        }
    }

    func deletePostAndWaitForSync(_ post: Post, postSyncedExpctation: XCTestExpectation? = nil) async throws {
        let deletedPost = postSyncedExpctation ?? expectation(description: "deleted Post")
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation deleted from the local
        // store and the second event due to the subscription event received from the remote store)
        deletedPost.expectedFulfillmentCount = 2
        deletedPost.assertForOverFulfill = false
        Amplify.DataStore.publisher(for: Post.self).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { mutationEvent in
            if mutationEvent.modelId == post.id {
                deletedPost.fulfill()
            }
        }.store(in: &cancellables)
        
        _ = try await Amplify.DataStore.delete(post)
        if postSyncedExpctation == nil {
            await waitForExpectations(timeout: 100)
        }
    }

    func queryNumberOfPosts() async -> Int {
        let querySuccess = expectation(description: "Query successful")
        var numberOfPosts = 0
        Amplify.DataStore.query(Post.self) { result in
            switch result {
            case .success(let posts):
                numberOfPosts = posts.count
                querySuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        await waitForExpectations(timeout: 100)
        return numberOfPosts
    }
}

extension DataStoreObserveQueryTests: DefaultLogger { }
