//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
// swiftlint:disable file_length
@available(iOS 13.0, *)
class DataStoreObserveQueryTests: SyncEngineIntegrationTestBase {

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
    func testObserveQueryInitialSync() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        snapshotWithIsSynced.assertForOverFulfill = false
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
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
        }

        savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()))
        wait(for: [snapshotWithIsSynced], timeout: 100)

        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        sink.cancel()
    }

    /// ObserveQuery API will eventually return a snapshot when sync state is toggled  from false to true.
    ///  A `.modelSynced` event from the hub is internally received
    ///
    /// - Given: DataStore is cleared
    /// - When:
    ///    - ObserveQuery API is called to start the sync engine
    ///    - A model is saved but not yet synced
    /// - Then:
    ///    - A query snapshot is received on `.modelSynced`
    ///
    func testObserveQueryWhenModelSyncedEvent() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        var isObserveQueryReadyForTest = false
        let observeQueryReadyForTest = expectation(description: "received query snapshot with .isSynced true")
        let snapshotWithPost = expectation(description: "received first snapshot")
        let post = Post(title: "title", content: "content", createdAt: .now())
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshots.append(querySnapshot)
            if !isObserveQueryReadyForTest && querySnapshot.isSynced {
                isObserveQueryReadyForTest = true
                observeQueryReadyForTest.fulfill()
            }
            if querySnapshot.items.contains(where: { $0.id == post.id }) {
                snapshotWithPost.fulfill()
            }
        }

        wait(for: [observeQueryReadyForTest], timeout: 100)

        _ = Amplify.DataStore.save(post)
        wait(for: [snapshotWithPost], timeout: 100)
        sink.cancel()
    }

    /// Apply a query predicate "title begins with 'xyz'"
    ///
    /// - Given: DataStore is set up with an empty local store
    /// - When:
    ///    - ObserveQuery is called with a predicate
    /// - Then:
    ///    - The models only contain models based on the predicate
    ///
    func testInitialSyncWithPredicate() throws {
        setUp(withModels: TestModelRegistration(), logLevel: .info)
        try startAmplify()
        savePostAndWaitForSync(Post(title: "xyz 1", content: "content", createdAt: .now()))
        savePostAndWaitForSync(Post(title: "xyz 2", content: "content", createdAt: .now()))
        savePostAndWaitForSync(Post(title: "xyz 3", content: "content", createdAt: .now()))
        clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        let receivedPostFromObserveQuery = expectation(description: "received Post")
        snapshotWithIsSynced.assertForOverFulfill = false
        var snapshotWithIsSyncedFulfilled = false
        let predicate = Post.keys.title.beginsWith("xyz")
        let sink = Amplify.DataStore.observeQuery(for: Post.self, where: predicate).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshots.append(querySnapshot)
            if !snapshotWithIsSyncedFulfilled && querySnapshot.isSynced {
                snapshotWithIsSyncedFulfilled = true
                snapshotWithIsSynced.fulfill()
            } else if snapshotWithIsSyncedFulfilled {
                if querySnapshot.items.count >= 4 && querySnapshot.items.contains(where: { post in
                    post.title.contains("xyz")
                }) {
                    receivedPostFromObserveQuery.fulfill()
                }
            }
        }

        savePostAndWaitForSync(Post(title: "xyz 4", content: "content", createdAt: .now()))
        wait(for: [snapshotWithIsSynced, receivedPostFromObserveQuery], timeout: 200)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        log.info("\(snapshots)")
        sink.cancel()
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
    func testObserveQueryWithSort() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplify()
        clearDataStore()
        let post1 = Post(title: "title", content: "content", createdAt: .now())
        let post2 = Post(title: "title", content: "content", createdAt: .now().add(value: 1, to: .second))
        let snapshotWithSavedPost = expectation(description: "query snapshot with saved post")
        let sink = Amplify.DataStore.observeQuery(for: Post.self,
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
            }

        savePostAndWaitForSync(post1)
        savePostAndWaitForSync(post2)
        wait(for: [snapshotWithSavedPost], timeout: 100)
        sink.cancel()
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
    func testObserveQueryWithDataStoreDeltaSync() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()))
        let numberOfPosts = queryNumberOfPosts()
        XCTAssertTrue(numberOfPosts > 0)
        stopDataStore()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        snapshotWithIsSynced.assertForOverFulfill = false
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
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
        }
        savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()))
        wait(for: [snapshotWithIsSynced], timeout: 100)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        XCTAssertTrue(snapshots.last!.isSynced)
        XCTAssertTrue(snapshots.last!.items.count > numberOfPosts)
        sink.cancel()
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
    func testPredicateWithCreateUpdateDelete() throws {
        setUp(withModels: TestModelRegistration(), logLevel: .info)
        try startAmplifyAndWaitForReady()

        let testId = UUID().uuidString
        let postMatchPredicate = Post(title: "xyz 1", content: testId, createdAt: .now())
        let postDoesNotMatch = Post(title: "doesNotMatch", content: testId, createdAt: .now())

        var snapshotCount = 0
        let allSnapshotsReceived = expectation(description: "query snapshots received")
        let predicate = Post.keys.title.beginsWith("xyz") && Post.keys.content == testId
        let sink = Amplify.DataStore.observeQuery(for: Post.self, where: predicate).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            switch snapshotCount {
            case 1:
                self.log.info("1. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
            case 2, 3:
                // See (1), subsequent snapshot should have item with "xyz 1".
                self.log.info("2/3. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 1")
            case 4:
                // See (2), should not be added to the snapshot.
                // See (3), should be removed from the snapshot. So the resulting snapshot is empty.
                self.log.info("4. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
            case 5, 6:
                // See (4). the post that now matches the snapshot should be added
                self.log.info("5/6. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 2")
            case 7:
                // See (5). the post that matched the predicate was deleted
                self.log.info("7. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
            case 8:
                // See (6). Snapshot that is emitted due to "xyz 3" should not contain the deleted model
                self.log.info("8. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 3")
                allSnapshotsReceived.fulfill()
            default:
                break
            }
        }

        // (1) Add model that matches predicate - should be received on the snapshot
        savePostAndWaitForSync(postMatchPredicate)

        // (2) Add model that does not match predicate - should not be received on the snapshot
        savePostAndWaitForSync(postDoesNotMatch)

        // (3) Update model that used to match the predicate to no longer match - should be removed from snapshot
        var postMatchPredicateNoLongerMatches = postMatchPredicate
        postMatchPredicateNoLongerMatches.title = "doesNotMatch"
        savePostAndWaitForSync(postMatchPredicateNoLongerMatches)

        // (4) Update model that does not match predicate to match - should be added to snapshot
        var postDoesNotMatchNowMatches = postDoesNotMatch
        postDoesNotMatchNowMatches.title = "xyz 2"
        savePostAndWaitForSync(postDoesNotMatchNowMatches)

        // (5) Delete the model that matches the predicate - should be removed
        deletePostAndWaitForSync(postDoesNotMatchNowMatches)

        // (6) Delete the model that does not match predicate - should have no snapshot emitted
        deletePostAndWaitForSync(postMatchPredicateNoLongerMatches)
        // Save "xyz 3" to force a snapshot to be emitted
        savePostAndWaitForSync(Post(title: "xyz 3", content: testId, createdAt: .now()))

        wait(for: [allSnapshotsReceived], timeout: 200)
        sink.cancel()
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
    func testSortWithCreateUpdateDelete() throws {
        setUp(withModels: TestModelRegistration(), logLevel: .info)
        try startAmplifyAndWaitForReady()

        let testId = UUID().uuidString
        var snapshotCount = 0
        let allSnapshotsReceived = expectation(description: "query snapshots received")
        let sink = Amplify.DataStore.observeQuery(for: Post.self,
                                                     where: Post.keys.content == testId,
                                                     sort: .ascending(Post.keys.title))
            .sink { completed in
                switch completed {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("\(error)")
                }
            } receiveValue: { querySnapshot in
                snapshotCount += 1

                let items = querySnapshot.items
                switch snapshotCount {
                case 1:
                    XCTAssertEqual(items.count, 0)
                case 2, 3:
                    XCTAssertEqual(items.count, 1)
                    XCTAssertEqual(items[0].title, "a")
                case 4, 5:
                    XCTAssertEqual(items.count, 2)
                    XCTAssertEqual(items[0].title, "a")
                    XCTAssertEqual(items[1].title, "m")
                case 6, 7:
                    XCTAssertEqual(items.count, 3)
                    XCTAssertEqual(items[0].title, "a")
                    XCTAssertEqual(items[1].title, "m")
                    XCTAssertEqual(items[2].title, "z")
                case 8, 9:
                    XCTAssertEqual(items.count, 3)
                    XCTAssertEqual(items[0].title, "m")
                    XCTAssertEqual(items[1].title, "n")
                    XCTAssertEqual(items[2].title, "z")
                case 10, 11:
                    XCTAssertEqual(items.count, 3)
                    XCTAssertEqual(items[0].title, "b")
                    XCTAssertEqual(items[1].title, "m")
                    XCTAssertEqual(items[2].title, "n")
                case 12:
                    XCTAssertEqual(items.count, 2)
                    XCTAssertEqual(items[0].title, "b")
                    XCTAssertEqual(items[1].title, "n")
                case 13:
                    XCTAssertEqual(items.count, 1)
                    XCTAssertEqual(items[0].title, "b")
                case 14:
                    XCTAssertEqual(items.count, 0)
                    allSnapshotsReceived.fulfill()
                default:
                    break
                }

            }

        // (1) Add several models
        let postA = Post(title: "a", content: testId, createdAt: .now())
        savePostAndWaitForSync(postA)

        let postM = Post(title: "m", content: testId, createdAt: .now())
        savePostAndWaitForSync(postM)

        let postZ = Post(title: "z", content: testId, createdAt: .now())
        savePostAndWaitForSync(postZ)

        // (2) Update models to move them into different orders
        var postNFromA = postA
        postNFromA.title = "n"
        savePostAndWaitForSync(postNFromA)

        var postBFromZ = postZ
        postBFromZ.title = "b"
        savePostAndWaitForSync(postBFromZ)

        // (3) Delete models
        deletePostAndWaitForSync(postM)
        deletePostAndWaitForSync(postNFromA)
        deletePostAndWaitForSync(postBFromZ)

        wait(for: [allSnapshotsReceived], timeout: 100)

        sink.cancel()
    }

    /// Ensure stopping datastore will not complete the observeQuery subscribers.
    ///
    /// - Given: DataStore is ready, first snapshot received.
    /// - When:
    ///    - DataStore.stop
    /// - Then:
    ///    -  ObserveQuery is not completed.
    ///
    func testObserveQueryShouldResetOnDataStoreStop() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        let firstSnapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                firstSnapshotWithIsSynced.fulfill()
            }
        }
        wait(for: [firstSnapshotWithIsSynced], timeout: 100)
        let stopCompleted = expectation(description: "DataStore stop completed")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                stopCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopCompleted, observeQueryReceivedCompleted], timeout: 10)
        sink.cancel()
    }

    /// Ensure clearing datastore will not complete the observeQuery subscribers.
    ///
    /// - Given: DataStore is ready, first snapshot received.
    /// - When:
    ///    - DataStore.clear
    /// - Then:
    ///    -  ObserveQuery is not completed.
    ///
    func testObserveQueryShouldResetOnDataStoreClear() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        let firstSnapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                firstSnapshotWithIsSynced.fulfill()
            }
        }
        wait(for: [firstSnapshotWithIsSynced], timeout: 100)
        let clearCompleted = expectation(description: "DataStore clear completed")
        Amplify.DataStore.clear { result in
            switch result {
            case .success:
                clearCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [clearCompleted, observeQueryReceivedCompleted], timeout: 10)
        sink.cancel()
    }

    func testObserveQueryShouldStartOnDataStoreStart() throws {
        setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForReady()
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        let observeQueryReceivedCompleted = expectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                observeQueryReceivedCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            }
        }
        wait(for: [firstSnapshot], timeout: 100)
        let stopCompleted = expectation(description: "DataStore stop completed")
        Amplify.DataStore.stop { result in
            switch result {
            case .success:
                stopCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopCompleted, observeQueryReceivedCompleted], timeout: 10)
        let startCompleted = expectation(description: "DataStore start completed")
        Amplify.DataStore.start { result in
            switch result {
            case .success:
                startCompleted.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [startCompleted, secondSnapshot], timeout: 10)
        sink.cancel()
    }

    // MARK: - Helpers

    func savePostAndWaitForSync(_ post: Post) {
        let receivedPost = expectation(description: "received Post")
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation saved to the local store
        // and the second event due to the subscription event received from the remote store)
        receivedPost.expectedFulfillmentCount = 2
        let sink = Amplify.DataStore.publisher(for: Post.self).sink { completion in
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
        }
        _ = Amplify.DataStore.save(post)
        wait(for: [receivedPost], timeout: 100)
        sink.cancel()
    }

    func deletePostAndWaitForSync(_ post: Post) {
        let deletedPost = expectation(description: "deleted Post")
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation deleted from the local
        // store and the second event due to the subscription event received from the remote store)
        deletedPost.expectedFulfillmentCount = 2
        let sink = Amplify.DataStore.publisher(for: Post.self).sink { completion in
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
        }
        _ = Amplify.DataStore.delete(post)
        wait(for: [deletedPost], timeout: 100)
        sink.cancel()
    }

    func queryNumberOfPosts() -> Int {
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
        wait(for: [querySuccess], timeout: 2)
        return numberOfPosts
    }
}

@available(iOS 13.0, *)
extension DataStoreObserveQueryTests: DefaultLogger { }
