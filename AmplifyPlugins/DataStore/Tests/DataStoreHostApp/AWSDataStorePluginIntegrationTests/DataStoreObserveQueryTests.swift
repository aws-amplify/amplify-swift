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
    func testObserveQueryAsyncInitialSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        try await clearDataStore()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        let querySnapshotsCancelled = expectation(description: "query snapshots cancelled")
        let querySnapshots = Amplify.DataStore.observeQuery(for: Post.self)
        let task = Task {
            var snapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in querySnapshots {
                    snapshots.append(querySnapshot)
                    if querySnapshot.isSynced {
                        snapshotWithIsSynced.fulfill()
                    }
                }
            } catch {
                XCTFail("\(error)")
            }
            XCTAssertTrue(snapshots.count >= 2)
            XCTAssertFalse(snapshots[0].isSynced)
            querySnapshotsCancelled.fulfill()
        }
        let receivedPost = expectation(description: "received Post")
        try await savePostAndWaitForSync(Post(title: "title", content: "content", createdAt: .now()),
                                         postSyncedExpctation: receivedPost)
        await fulfillment(of: [snapshotWithIsSynced, receivedPost], timeout: 100)
        task.cancel()
        await fulfillment(of: [querySnapshotsCancelled], timeout: 10)
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
        try await clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self)).sink { completed in
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
        await fulfillment(of: [snapshotWithIsSynced, receivedPost], timeout: 100)
        
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
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
    func testObserveQueryWhenModelSyncedEvent() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplify()
        try await clearDataStore()
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        var isObserveQueryReadyForTest = false
        let observeQueryReadyForTest = expectation(description: "received query snapshot with .isSynced true")
        let snapshotWithPost = expectation(description: "received first snapshot")
        let post = Post(title: "title", content: "content", createdAt: .now())
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self)).sink { completed in
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
        }.store(in: &cancellables)
        await fulfillment(of: [observeQueryReadyForTest], timeout: 100)
        
        _ = try await Amplify.DataStore.save(post)
        await fulfillment(of: [snapshotWithPost], timeout: 100)
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
        let startTime = Temporal.DateTime.now()
        await setUp(
            withModels: TestModelRegistration(),
            logLevel: .verbose,
            dataStoreConfiguration: .custom(
                syncMaxRecords: 100,
                syncExpressions: [
                    DataStoreSyncExpression(
                        modelSchema: Post.schema,
                        modelPredicate: { Post.keys.createdAt.ge(startTime) }
                    )
                ]
            )
        )
        try startAmplify()

        let randomTitle = UUID().uuidString
        let post1 = Post(title: "\(randomTitle) 1", content: "content", createdAt: .now())
        let post2 = Post(title: "\(randomTitle) 2", content: "content", createdAt: .now())
        let post3 = Post(title: "\(randomTitle) 3", content: "content", createdAt: .now())
        try await savePostAndWaitForSync(post1)
        try await savePostAndWaitForSync(post2)
        try await savePostAndWaitForSync(post3)
        try await clearDataStore()

        var snapshots = [DataStoreQuerySnapshot<Post>]()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var snapshotWithIsSyncedFulfilled = false
        let receivedPostFromObserveQuery = expectation(description: "received Post")
        let post4 = Post(title: "\(randomTitle) 4", content: "content", createdAt: .now())
        let predicate = Post.keys.title.beginsWith(randomTitle)
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self, where: predicate)).sink { completed in
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
                if querySnapshot.items.count >= 4
                   && querySnapshot.items.allSatisfy({ $0.title.contains(randomTitle)})
                {
                    receivedPostFromObserveQuery.fulfill()
                }
            }
            
        }.store(in: &cancellables)

        await fulfillment(of: [snapshotWithIsSynced], timeout: 100)

        try await savePostAndWaitForSync(post4)
        await fulfillment(of: [receivedPostFromObserveQuery], timeout: 100)
        
        XCTAssertTrue(snapshots.count >= 2)
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
        try await clearDataStore()
        let post1 = Post(title: "title", content: "content", createdAt: .now())
        let post2 = Post(title: "title", content: "content", createdAt: .now().add(value: 1, to: .second))
        let snapshotWithSavedPost = expectation(description: "query snapshot with saved post")
        snapshotWithSavedPost.expectedFulfillmentCount = 2
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self, sort: .ascending(Post.keys.createdAt)))
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

        try await savePostAndWaitForSync(post1)
        try await savePostAndWaitForSync(post2)
        await fulfillment(of: [snapshotWithSavedPost], timeout: 100)
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
        let numberOfPosts = try await queryNumberOfPosts()
        XCTAssertTrue(numberOfPosts > 0)
        try await stopDataStore()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var snapshots = [DataStoreQuerySnapshot<Post>]()
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self)).sink { completed in
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
        await fulfillment(of: [snapshotWithIsSynced, receivedPost], timeout: 30)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        XCTAssertTrue(snapshots.last!.isSynced)
        XCTAssertTrue(snapshots.last!.items.count > numberOfPosts)
    }


    /// ObserveQuery with DataStore sync. Ensure datastore is cleared.
    /// When ObserveQuery is called, it will start DataStore and perform a full sync on max records.
    ///
    /// - Given: DataStore is cleared.
    /// - When:
    ///    - ObserveQuery is called to do perform full sync
    /// - Then:
    ///    - The first snapshot should have the old data and `isSynced` false
    ///    - The final snapshot should have all the latest models with `isSynced` true
    ///
    func testObserveQuery_withClearedDataStore_fullySyncedWithMaxRecords() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        try await clearDataStore()

        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var snapshots = [DataStoreQuerySnapshot<Post>]()

        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self)).sink { completed in
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

        let newPost = Post(title: "title", content: "content", createdAt: .now())
        let receivedPost = expectation(description: "received Post")
        try await savePostAndWaitForSync(newPost,
                                         postSyncedExpctation: receivedPost)

        await fulfillment(of: [snapshotWithIsSynced, receivedPost], timeout: 30)
        XCTAssertTrue(snapshots.count >= 2)
        XCTAssertFalse(snapshots[0].isSynced)
        XCTAssertEqual(1, snapshots.filter({ $0.isSynced }).count)

        let theSyncedSnapshot = snapshots.first(where: { $0.isSynced })
        XCTAssertNotNil(theSyncedSnapshot)
        XCTAssertTrue(theSyncedSnapshot!.items.contains(newPost))
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
        try await startAmplifyAndWaitForReady()
        let testId = UUID().uuidString
        var snapshotCount = 0
        let predicate = Post.keys.title.beginsWith("xyz") && Post.keys.content == testId
        let snapshotExpectation1 = expectation(description: "received snapshot 1")
        let snapshotExpectation23 = expectation(description: "received snapshot 2 / 3")
        snapshotExpectation23.expectedFulfillmentCount = 2

        let snapshotExpectation4 = expectation(description: "received snapshot 4")
        let snapshotExpectation56 = expectation(description: "received snapshot 5 / 6")
        snapshotExpectation56.expectedFulfillmentCount = 2
        let snapshotExpectation7 = expectation(description: "received snapshot 7")
        let snapshotExpectation8 = expectation(description: "received snapshot 8")
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self, where: predicate)).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            snapshotCount += 1
            let items = querySnapshot.items
            if snapshotCount == 1 {
                self.log.info("\(#function) 1. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation1.fulfill()
            } else if snapshotCount == 2 || snapshotCount == 3 {
                // See (1), subsequent snapshot should have item with "xyz 1".
                self.log.info("\(#function) 2/3. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 1")
                snapshotExpectation23.fulfill()
            } else if snapshotCount == 4 {
                // See (2), should not be added to the snapshot.
                // See (3), should be removed from the snapshot. So the resulting snapshot is empty.
                self.log.info("\(#function) 4. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation4.fulfill()
            } else if snapshotCount == 5 || snapshotCount == 6 {
                // See (4). the post that now matches the snapshot should be added
                self.log.info("\(#function) 5/6. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 2")
                snapshotExpectation56.fulfill()
            } else if snapshotCount == 7 {
                // See (5). the post that matched the predicate was deleted
                self.log.info("\(#function) 7. \(querySnapshot)")
                XCTAssertEqual(items.count, 0)
                snapshotExpectation7.fulfill()
            } else if snapshotCount == 8 {
                // See (6). Snapshot that is emitted due to "xyz 3" should not contain the deleted model
                self.log.info("\(#function) 8. \(querySnapshot)")
                XCTAssertEqual(items.count, 1)
                XCTAssertEqual(items[0].title, "xyz 3")
                snapshotExpectation8.fulfill()
            }
        }.store(in: &cancellables)
        await fulfillment(of: [snapshotExpectation1], timeout: 10)
        
        // (1) Add model that matches predicate - should be received on the snapshot
        let postMatchPredicate = Post(title: "xyz 1", content: testId, createdAt: .now())
        
        try await savePostAndWaitForSync(postMatchPredicate)
        await fulfillment(of: [snapshotExpectation23], timeout: 10)
        
        // (2) Add model that does not match predicate - should not be received on the snapshot
        // (3) Update model that used to match the predicate to no longer match - should be removed from snapshot
        let postDoesNotMatch = Post(title: "doesNotMatch", content: testId, createdAt: .now())
        let postDoesNotMatchExpectation = expectation(description: "received postDoesNotMatchExpectation")
        try await savePostAndWaitForSync(postDoesNotMatch, postSyncedExpctation: postDoesNotMatchExpectation)
        var postMatchPredicateNoLongerMatches = postMatchPredicate
        postMatchPredicateNoLongerMatches.title = "doesNotMatch"
        try await savePostAndWaitForSync(postMatchPredicateNoLongerMatches)
        await fulfillment(of: [snapshotExpectation4], timeout: 10)
        
        // (4) Update model that does not match predicate to match - should be added to snapshot
        var postDoesNotMatchNowMatches = postDoesNotMatch
        postDoesNotMatchNowMatches.title = "xyz 2"
        try await savePostAndWaitForSync(postDoesNotMatchNowMatches)
        await fulfillment(of: [snapshotExpectation56], timeout: 10)
        
        // (5) Delete the model that matches the predicate - should be removed
        try await deletePostAndWaitForSync(postDoesNotMatchNowMatches)
        await fulfillment(of: [snapshotExpectation7], timeout: 10)
        
        // (6) Delete the model that does not match predicate - should have no snapshot emitted
        let postMatchPredicateNoLongerMatchesExpectation = expectation(description: " received")
        try await deletePostAndWaitForSync(postMatchPredicateNoLongerMatches,
                                           postSyncedExpctation: postMatchPredicateNoLongerMatchesExpectation)

        // Save "xyz 3" to force a snapshot to be emitted
        try await savePostAndWaitForSync(Post(title: "xyz 3", content: testId, createdAt: .now()))
        await fulfillment(of: [snapshotExpectation8], timeout: 10)
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
        try await startAmplifyAndWaitForReady()

        let testId = UUID().uuidString
        var snapshotCount = 0
        let observeQueryReadyForTest = expectation(description: "observeQuery initial query completed")
        let allSnapshotsReceived = expectation(description: "query snapshots received")
        let sink = Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self,
                                                     where: Post.keys.content == testId,
                                                     sort: .ascending(Post.keys.title)))
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
                    observeQueryReadyForTest.fulfill()
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

        await fulfillment(of: [observeQueryReadyForTest], timeout: 10)
        // (1) Add several models
        let postA = Post(title: "a", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postA)

        let postM = Post(title: "m", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postM)

        let postZ = Post(title: "z", content: testId, createdAt: .now())
        try await savePostAndWaitForSync(postZ)

        // (2) Update models to move them into different orders
        var postNFromA = postA
        postNFromA.title = "n"
        let postNFromAExpectation = expectation(description: "postNFromAExpectation")
        try await savePostAndWaitForSync(postNFromA, postSyncedExpctation: postNFromAExpectation)

        var postBFromZ = postZ
        postBFromZ.title = "b"
        let postBFromZExpectation = expectation(description: "postBFromZExpectation")
        try await savePostAndWaitForSync(postBFromZ, postSyncedExpctation: postBFromZExpectation)

        // (3) Delete models
        try await deletePostAndWaitForSync(postM)
        try await deletePostAndWaitForSync(postNFromA)
        try await deletePostAndWaitForSync(postBFromZ)

        await fulfillment(of: [allSnapshotsReceived], timeout: 100)

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
    func testObserveQueryShouldResetOnDataStoreStop() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let firstSnapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        var onComplete: ((Subscribers.Completion<Error>) -> Void) = { _ in }
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self))
            .sink { onComplete($0) } receiveValue: { querySnapshot in
                if querySnapshot.isSynced {
                    firstSnapshotWithIsSynced.fulfill()
                }
            }.store(in: &cancellables)
        await fulfillment(of: [firstSnapshotWithIsSynced], timeout: 10)
        
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
        try await Amplify.DataStore.stop()
        await fulfillment(of: [observeQueryReceivedCompleted], timeout: 10)
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
        var onComplete: ((Subscribers.Completion<Error>) -> Void) = { _ in }
        Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self))
            .sink { onComplete($0) } receiveValue: { querySnapshot in
                if querySnapshot.isSynced {
                    firstSnapshotWithIsSynced.fulfill()
                }
            }.store(in: &cancellables)
        await fulfillment(of: [firstSnapshotWithIsSynced], timeout: 100)
        
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
        try await Amplify.DataStore.clear()
        await fulfillment(of: [observeQueryReceivedCompleted], timeout: 10)
    }

    func testObserveQueryShouldStartOnDataStoreStart() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForReady()
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        let observeQueryReceivedCompleted = XCTestExpectation(description: "observeQuery received completed")
        observeQueryReceivedCompleted.isInverted = true
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let sink = Amplify.Publisher.create(Amplify.DataStore.observeQuery(for: Post.self)).sink { completed in
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
        await fulfillment(of: [firstSnapshot], timeout: 100)
        try await Amplify.DataStore.stop()
        await fulfillment(of: [observeQueryReceivedCompleted], timeout: 10)
        try await Amplify.DataStore.start()
        await fulfillment(of: [secondSnapshot], timeout: 10)
        sink.cancel()
    }

    // MARK: - Helpers
    func savePostAndWaitForSync(_ post: Post, postSyncedExpctation: XCTestExpectation? = nil) async throws {
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation saved to the local store
        // and the second event due to the subscription event received from the remote store)

        let receivedPost = postSyncedExpctation ?? {
            let e = expectation(description: "received Post")
            e.expectedFulfillmentCount = 2
            return e
        }()

        Task {
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.modelId == post.id {
                        receivedPost.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        _ = try await Amplify.DataStore.save(post)
        if postSyncedExpctation == nil {
            await fulfillment(of: [receivedPost], timeout: 100)
        }
    }

    func deletePostAndWaitForSync(_ post: Post, postSyncedExpctation: XCTestExpectation? = nil) async throws {
        // Wait for a fulfillment count of 2 (first event due to the locally source mutation deleted from the local
        // store and the second event due to the subscription event received from the remote store)
        let deletedPost = postSyncedExpctation ?? {
            let e = expectation(description: "deleted Post")
            e.expectedFulfillmentCount = 2
            return e
        }()

        Task {
            let mutationEvents = Amplify.DataStore.observe(Post.self)
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.modelId == post.id {
                        deletedPost.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed \(error)")
            }
        }
        
        _ = try await Amplify.DataStore.delete(post)
        if postSyncedExpctation == nil {
            await fulfillment(of: [deletedPost], timeout: 100)
        }
    }

    func queryNumberOfPosts() async throws -> Int {
        let posts = try await Amplify.DataStore.query(Post.self)
        return posts.count
    }
}

extension DataStoreObserveQueryTests: DefaultLogger { }
