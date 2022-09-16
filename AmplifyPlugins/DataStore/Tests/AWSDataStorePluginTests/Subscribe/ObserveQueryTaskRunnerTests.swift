//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

class ObserveQueryTaskRunnerTests: XCTestCase {
    var storageEngine: MockStorageEngineBehavior!
    var dataStorePublisher: ModelSubcriptionBehavior!
    var dataStoreStateSubject = PassthroughSubject<DataStoreState, DataStoreError>()

    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        storageEngine = MockStorageEngineBehavior()
        dataStorePublisher = DataStorePublisher()
    }
    
    ///  An item changed observed will be returned in a single snapshot
    ///
    /// - Given:  The operation has started and the first query has completed.
    /// - When:
    ///    -  Observe an item change.
    /// - Then:
    ///    - The item observed will be returned in the second snapshot
    ///
    func testItemChangedWillGenerateSnapshot() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshots")
        let secondSnapshot = asyncExpectation(description: "second query snapshots")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        XCTAssertEqual(querySnapshot.items.count, 0)
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        XCTAssertEqual(querySnapshot.items.count, 1)
                        await secondSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
    
        await waitForExpectations([firstSnapshot], timeout: 1)

        let post = try createPost(id: "1")
        dataStorePublisher.send(input: post)
        await waitForExpectations([secondSnapshot], timeout: 10)
    }
    
    ///  ObserveQuery will send a single snapshot when the sync state toggles
    ///  from false to true. The operation internally listens to .modelSynced event from
    ///  the Hub.
    ///
    /// - Given: ObserveQuery has started and the first snapshot has been received.
    /// - When:
    ///    - modelSyncedEvent is sent to the Hub
    /// - Then:
    ///    - ObserveQuery will send a second snapshot
    ///
    func testGenerateSnapshotOnObserveQueryWhenModelSynced() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshots")
        let secondSnapshot = asyncExpectation(description: "second query snapshots")
        let thirdSnapshot = asyncExpectation(description: "third query snapshot", isInverted: true)
        let dispatchedModelSyncedEvent = AtomicValue(initialValue: false)
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: dispatchedModelSyncedEvent,
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        XCTAssertEqual(querySnapshot.items.count, 0)
                        XCTAssertEqual(querySnapshot.isSynced, false)
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        XCTAssertEqual(querySnapshot.items.count, 0)
                        XCTAssertEqual(querySnapshot.isSynced, true)
                        await secondSnapshot.fulfill()
                    } else if querySnapshots.count == 3 {
                        XCTFail("Should not receive third snapshot for a Model change")
                        await thirdSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 5)
        
        dispatchedModelSyncedEvent.set(true)
        let modelSyncedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                                 data: ModelSyncedEvent(modelName: Post.modelName, isFullSync: true,
                                                                        isDeltaSync: false, added: 0, updated: 0,
                                                                        deleted: 0))
        Amplify.Hub.dispatch(to: .dataStore, payload: modelSyncedEventPayload)
        await waitForExpectations([secondSnapshot], timeout: 10)
        
        let modelSyncedEventNotMatch = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                                  data: ModelSyncedEvent.Builder().modelName)
        Amplify.Hub.dispatch(to: .dataStore, payload: modelSyncedEventNotMatch)
        await waitForExpectations([thirdSnapshot], timeout: 10)
    }
    
    /// ObserveQuery will send the first snapshot with 2 items when storage engine
    /// is mocked to return 2 items.
    ///
    /// - Given: ObserveQuery starts
    /// - When:
    ///    -  ObserveQuery performs the initial query, two posts are queried through StorageEngine
    /// - Then:
    ///    - The items queried will return two posts in the first snapshot
    ///
    func testFirstSnapshotFromStorageQueryReturnsTwoPosts() async {
        let firstSnapshot = asyncExpectation(description: "firstSnapshot received")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let post = Post(title: "model1",
                        content: "content1",
                        createdAt: .now())
        storageEngine.responders[.query] = QueryResponder<Post>(callback: { _ in
            return .success([post, Post(title: "model1", content: "content1", createdAt: .now())])
        })
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        XCTAssertEqual(querySnapshot.items.count, 2)
                        await firstSnapshot.fulfill()
                    }
                }
                
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        await waitForExpectations([firstSnapshot], timeout: 10)
    }
    
    /// Multiple item changed observed will be returned in a single snapshot
    ///
    /// - Given:  The operation has started and the first query has completed.
    /// - When:
    ///    -  Observe multiple item changes.
    /// - Then:
    ///    - The items observed will be returned in the second snapshot
    ///
    func testMultipleItemChangesWillGenerateSecondSnapshot() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot")

        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        XCTAssertEqual(querySnapshot.items.count, 0)
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        XCTAssertEqual(querySnapshot.items.count, 3)
                        await secondSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 1)

        let post1 = try createPost(id: "1")
        let post2 = try createPost(id: "2")
        let post3 = try createPost(id: "3")
        dataStorePublisher.send(input: post1)
        dataStorePublisher.send(input: post2)
        dataStorePublisher.send(input: post3)
        await waitForExpectations([secondSnapshot], timeout: 10)
    }
    
    /// Multiple published objects (more than the `.collect` count of 1000) in a relatively short time window
    /// will cause the operation in test to exceed the limit of 1000 in its collection of items before sending a snapshot.
    /// The first snapshot will have 1000 items, and subsequent snapshots will follow as the remaining objects are published and processed.
    ///
    /// - Given:  The operation has started and the first query has completed.
    /// - When:
    ///    -  Observe 1100 item changes (beyond the `.collect` count of 1000)
    /// - Then:
    ///    - The items observed will perform a query and return 1000 items changed in the second query and the
    ///     remaining in the third query
    ///
    func testCollectOverMaxItemCountLimit() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot")
        let thirdSnapshot = asyncExpectation(description: "third query snapshot")
        let validateSnapshotsComplete = asyncExpectation(description: "validate snapshots")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        await secondSnapshot.fulfill()
                    } else if querySnapshots.count == 3 {
                        await thirdSnapshot.fulfill()
                    }
                }
                
                XCTAssertTrue(querySnapshots.count >= 3)
                XCTAssertTrue(querySnapshots[0].items.count <= querySnapshots[1].items.count)
                XCTAssertTrue(querySnapshots[1].items.count <= querySnapshots[2].items.count)
                XCTAssertTrue(querySnapshots[2].items.count <= 1_100)
                await validateSnapshotsComplete.fulfill()
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 1)

        for postId in 1 ... 1_100 {
            let post = try createPost(id: "\(postId)")
            dataStorePublisher.send(input: post)
        }

        await waitForExpectations([secondSnapshot, thirdSnapshot], timeout: 10)
        snapshots.cancel()
        await waitForExpectations([validateSnapshotsComplete], timeout: 1.0)
    }
    
    /// Cancelling the subscription will no longer receive snapshots
    ///
    /// - Given:  subscriber to the operation
    /// - When:
    ///    - subscriber is cancelled
    /// - Then:
    ///    - no further snapshots are received
    ///
    func testSuccessfulSubscriptionCancel() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot", isInverted: true)
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        XCTFail("Should not receive second snapshot after cancelling")
                        await secondSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 1)
        snapshots.cancel()
        let post1 = try createPost(id: "1")
        dataStorePublisher.send(input: post1)
        await waitForExpectations([secondSnapshot], timeout: 1)
    }
    
    /// Cancelling the underlying operation will emit a completion to the subscribers
    ///
    /// - Given:  subscriber to the operation
    /// - When:
    ///    - operation is cancelled
    /// - Then:
    ///    - the subscriber receives a cancellation
    ///
    func testSuccessfulSequenceCancel() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot", isInverted: true)
        let completedEvent = asyncExpectation(description: "should have completed")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        XCTFail("Should not receive second snapshot after cancelling")
                        await secondSnapshot.fulfill()
                    }
                }
                await completedEvent.fulfill()
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        await waitForExpectations([firstSnapshot], timeout: 1)
        snapshots.cancel()
        let post1 = try createPost(id: "1")
        dataStorePublisher.send(input: post1)

        await waitForExpectations([secondSnapshot, completedEvent], timeout: 1)
    }
    
    ///  ObserveQuery's state should be able to be reset and initial query able to be started again.
    func testObserveQueryResetStateThenStartObserveQuery() async {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        await secondSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 1)
        dataStoreStateSubject.send(.stop)
        dataStoreStateSubject.send(.start(storageEngine: storageEngine))
        await waitForExpectations([secondSnapshot], timeout: 1)
    }
    
    /// Multiple calls to start the observeQuery should not start again
    ///
    /// - Given: ObserverQuery operation is created, and then reset
    /// - When:
    ///    - operation.startObserveQuery twice
    /// - Then:
    ///    - Only one query should be performed / only one snapshot should be returned
    func testObserveQueryStaredShouldNotStartAgain() async {
        let firstSnapshot = asyncExpectation(description: "first query snapshot")
        let secondSnapshot = asyncExpectation(description: "second query snapshot")
        let thirdSnapshot = asyncExpectation(description: "third query snapshot", isInverted: true)
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        await secondSnapshot.fulfill()
                    } else if querySnapshots.count == 3 {
                        await thirdSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        await waitForExpectations([firstSnapshot], timeout: 1)
        dataStoreStateSubject.send(.stop)
        dataStoreStateSubject.send(.start(storageEngine: storageEngine))
        dataStoreStateSubject.send(.start(storageEngine: storageEngine))
        await waitForExpectations([secondSnapshot, thirdSnapshot], timeout: 1)
        XCTAssertTrue(taskRunner.observeQueryStarted)
    }
    
    /// ObserveQuery operation entry points are `resetState`, `startObserveQuery`, and `onItemChanges(mutationEvents)`.
    /// Ensure concurrent random sequences of these API calls do not cause issues such as data race.
    func testConcurrent() async {
        let completeReceived = asyncExpectation(description: "complete received", isInverted: true)
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())
        let post = Post(title: "model1",
                        content: "content1",
                        createdAt: .now())
        storageEngine.responders[.query] = QueryResponder<Post>(callback: { _ in
            return .success([post, Post(title: "model1", content: "content1", createdAt: .now())])
        })
        let snapshots = taskRunner.sequence
        Task {
            do {
                for try await _ in snapshots {
                }
                await completeReceived.fulfill()
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<3000 {
                group.addTask {
                    let index = Int.random(in: 1 ... 5)
                    if index == 1 {
                        self.dataStoreStateSubject.send(.stop)
                    } else if index == 2 {
                        self.dataStoreStateSubject.send(.start(storageEngine: self.storageEngine))
                    } else {
                        do {
                            let itemChange = try self.createPost(id: post.id)
                            let itemChange2 = try self.createPost()
                            taskRunner.onItemsChangeDuringSync(mutationEvents: [itemChange, itemChange2])
                        } catch {
                            XCTFail("Failed to create post")
                        }
                    }
                }
            }
            for await _ in group {
            }
        }
        await waitForExpectations([completeReceived], timeout: 10)
    }
    
    /// When a predicate like `title.beginsWith("title")` is given, the models that matched the predicate
    /// should be added to the snapshots, like `post` and `post2`. When `post2.title` is updated to no longer
    /// match the predicate, it should be removed from the snapshot.
    func testUpdatedModelNoLongerMatchesPredicateRemovedFromSnapshot() async throws {
        let firstSnapshot = asyncExpectation(description: "first query snapshots")
        let secondSnapshot = asyncExpectation(description: "second query snapshots")
        let thirdSnapshot = asyncExpectation(description: "third query snapshots")
        let fourthSnapshot = asyncExpectation(description: "fourth query snapshots")
        let taskRunner = ObserveQueryTaskRunner(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: Post.keys.title.beginsWith("title"),
            sortInput: QuerySortInput.ascending(Post.keys.id).asSortDescriptors(),
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: true),
            dataStoreStatePublisher: dataStoreStateSubject.eraseToAnyPublisher())

        let snapshots = taskRunner.sequence
        Task {
            var querySnapshots = [DataStoreQuerySnapshot<Post>]()
            do {
                for try await querySnapshot in snapshots {
                    querySnapshots.append(querySnapshot)
                    if querySnapshots.count == 1 {
                        // First snapshot is empty from the initial query
                        XCTAssertEqual(querySnapshot.items.count, 0)
                        await firstSnapshot.fulfill()
                    } else if querySnapshots.count == 2 {
                        // Second snapshot contains `post` since it matches the predicate
                        XCTAssertEqual(querySnapshot.items.count, 1)
                        XCTAssertEqual(querySnapshot.items[0].id, "1")
                        await secondSnapshot.fulfill()
                    } else if querySnapshots.count == 3 {
                        // Third snapshot contains both posts since they both match the predicate
                        XCTAssertEqual(querySnapshot.items.count, 2)
                        XCTAssertEqual(querySnapshot.items[0].id, "1")
                        XCTAssertEqual(querySnapshot.items[1].id, "2")
                        await thirdSnapshot.fulfill()
                    } else if querySnapshots.count == 4 {
                        // Fourth snapshot no longer has the post2 since it was updated to not match the predicate
                        // and deleted at the same time.
                        XCTAssertEqual(querySnapshot.items.count, 1)
                        XCTAssertEqual(querySnapshot.items[0].id, "1")
                        await fourthSnapshot.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        await waitForExpectations([firstSnapshot], timeout: 5)

        let post = try createPost(id: "1", title: "title 1")
        dataStorePublisher.send(input: post)
        let post2 = try createPost(id: "2", title: "title 2")
        dataStorePublisher.send(input: post2)
        var updatedPost2 = try createPost(id: "2", title: "Does not match predicate")
        updatedPost2.mutationType = MutationEvent.MutationType.update.rawValue
        dataStorePublisher.send(input: updatedPost2)
        await waitForExpectations([secondSnapshot, thirdSnapshot, fourthSnapshot], timeout: 10)
    }
    
    
    // MARK: - Helpers

    func createPost(id: String = UUID().uuidString, title: String? = nil) throws -> MutationEvent {
        try MutationEvent(model: Post(id: id,
                                      title: title ?? "model1",
                                      content: "content1",
                                      createdAt: .now()),
                          modelSchema: Post.schema,
                          mutationType: MutationEvent.MutationType.create)
    }
}
