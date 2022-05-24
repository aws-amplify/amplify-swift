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
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable type_body_length
class DataStoreObserveQueryOperationTests: XCTestCase {

    var storageEngine: MockStorageEngineBehavior!
    var dataStorePublisher: ModelSubcriptionBehavior!

    override func setUp() {
        ModelRegistry.register(modelType: Post.self)
        storageEngine = MockStorageEngineBehavior()
        dataStorePublisher = DataStorePublisher()
    }

    /// After the query finishes, observed item changes will generate a snapshot.
    ///
    /// - Given:  The operation has started and the initial query has completed.
    /// - When:
    ///    -  Item change occurs.
    /// - Then:
    ///    - Receive a snapshot with the item changed
    ///
    func testItemChangedWillGenerateSnapshot() throws {
        let firstSnapshot = expectation(description: "first query snapshots")
        let secondSnapshot = expectation(description: "second query snapshots")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)

        let post = try createPost(id: "1")
        dataStorePublisher.send(input: post)
        wait(for: [secondSnapshot], timeout: 10)

        XCTAssertEqual(querySnapshots.count, 2)
        XCTAssertEqual(querySnapshots[0].items.count, 0)
        XCTAssertEqual(querySnapshots[1].items.count, 1)
        sink.cancel()
    }

    /// Multiple item changed observed will be returned in a single snapshot
    ///
    /// - Given:  The operation has started and the first query has completed.
    /// - When:
    ///    -  Observe multiple item changes.
    /// - Then:
    ///    - The items observed will be returned in the second snapshot
    ///
    func testMultipleItemChangesWillGenerateSecondSnapshot() throws {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")

        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)

        let post1 = try createPost(id: "1")
        let post2 = try createPost(id: "2")
        let post3 = try createPost(id: "3")
        dataStorePublisher.send(input: post1)
        dataStorePublisher.send(input: post2)
        dataStorePublisher.send(input: post3)
        wait(for: [secondSnapshot], timeout: 10)

        XCTAssertEqual(querySnapshots.count, 2)
        XCTAssertEqual(querySnapshots[0].items.count, 0)
        XCTAssertEqual(querySnapshots[1].items.count, 3)
        sink.cancel()
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
    func testCollectOverMaxItemCountLimit() throws {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        let thirdSnapshot = expectation(description: "third query snapshot")

        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            } else if querySnapshots.count == 3 {
                thirdSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)

        for postId in 1 ... 1_100 {
            let post = try createPost(id: "\(postId)")
            dataStorePublisher.send(input: post)
        }

        wait(for: [secondSnapshot, thirdSnapshot], timeout: 10)

        XCTAssertTrue(querySnapshots.count >= 3)
        XCTAssertTrue(querySnapshots[0].items.count <= querySnapshots[1].items.count)
        XCTAssertTrue(querySnapshots[1].items.count <= querySnapshots[2].items.count)
        XCTAssertTrue(querySnapshots[2].items.count <= 1_100)
        sink.cancel()
    }

    /// Cancelling the subscription will no longer receive snapshots
    ///
    /// - Given:  subscriber to the operation
    /// - When:
    ///    - subscriber is cancelled
    /// - Then:
    ///    - no further snapshots are received
    ///
    func testSuccessfulSubscriptionCancel() throws {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        secondSnapshot.isInverted = true
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { snapshot in
            querySnapshots.append(snapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
                XCTFail("Should not receive second snapshot after cancelling")
            }
        }

        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)
        sink.cancel()
        let post1 = try createPost(id: "1")
        dataStorePublisher.send(input: post1)

        wait(for: [secondSnapshot], timeout: 1)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
    }

    /// Cancelling the underlying operation will emit a completion to the subscribers
    ///
    /// - Given:  subscriber to the operation
    /// - When:
    ///    - operation is cancelled
    /// - Then:
    ///    - the subscriber receives a cancellation
    ///
    func testSuccessfulOperationCancel() throws {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        secondSnapshot.isInverted = true
        let completedEvent = expectation(description: "should have completed")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                completedEvent.fulfill()
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { snapshot in
            querySnapshots.append(snapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
                XCTFail("Should not receive second snapshot after cancelling")
            }
        }

        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)
        operation.cancel()
        let post1 = try createPost(id: "1")
        dataStorePublisher.send(input: post1)

        wait(for: [secondSnapshot], timeout: 1)
        wait(for: [completedEvent], timeout: 1)
        XCTAssertTrue(operation.isCancelled)
        XCTAssertTrue(operation.isFinished)
    }

    ///  ObserveQuery's state should be able to be reset and initial query able to be started again.
    func testObserveQueryResetStateThenStartObserveQuery() {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        var sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)

        wait(for: [firstSnapshot], timeout: 1)
        operation.resetState()
        operation.startObserveQuery(with: storageEngine)
        wait(for: [secondSnapshot], timeout: 1)
    }

    /// Multiple calls to start the observeQuery should not start again
    ///
    /// - Given: ObserverQuery operation is created, and then reset
    /// - When:
    ///    - operation.startObserveQuery twice
    /// - Then:
    ///    - Only one query should be performed / only one snapshot should be returned
    func testObserveQueryStaredShouldNotStartAgain() {
        let firstSnapshot = expectation(description: "first query snapshot")
        let secondSnapshot = expectation(description: "second query snapshot")
        let thirdSnapshot = expectation(description: "third query snapshot")
        thirdSnapshot.isInverted = true
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        var sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { snapshot in
            querySnapshots.append(snapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            } else if querySnapshots.count == 3 {
                thirdSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 1)

        operation.resetState()

        operation.startObserveQuery(with: storageEngine)
        operation.startObserveQuery(with: storageEngine)
        wait(for: [secondSnapshot], timeout: 1)
        wait(for: [thirdSnapshot], timeout: 1)
        XCTAssertTrue(operation.observeQueryStarted)
    }

    func testObserveQueryOperationIsRemovedWhenPreviousSubscriptionIsRemoved() {
        let firstSnapshot = expectation(description: "first query snapshot")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation1 = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        let operation2 = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))

        var sink = operation1.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { _ in
            XCTFail("Should not receive snapshot when cancelled immediately")
        }

        sink = operation2.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { snapshot in
            querySnapshots.append(snapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation1)
        queue.addOperation(operation2)

        wait(for: [firstSnapshot], timeout: 10)
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertTrue(operation2.isExecuting)
        sink.cancel()
    }

    /// ObserveQuery operation entry points are `resetState`, `startObserveQuery`, and `onItemChanges(mutationEvents)`.
    /// Ensure concurrent random sequences of these API calls do not cause issues such as data race.
    func testConcurrent() {
        let completeReceived = expectation(description: "complete received")
        completeReceived.isInverted = true
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: nil,
            sortInput: nil,
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: false))
        let post = Post(title: "model1",
                        content: "content1",
                        createdAt: .now())
        storageEngine.responders[.query] = QueryResponder<Post>(callback: { _ in
            return .success([post, Post(title: "model1", content: "content1", createdAt: .now())])
        })
        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                completeReceived.fulfill()
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { _ in }
        let queue = OperationQueue()
        queue.addOperation(operation)
        DispatchQueue.concurrentPerform(iterations: 3_000) { _ in
            let index = Int.random(in: 1 ... 5)
            if index == 1 {
                operation.resetState()
            } else if index == 2 {
                operation.startObserveQuery(with: storageEngine)
            } else {
                do {
                    let itemChange = try createPost(id: post.id)
                    let itemChange2 = try createPost()
                    operation.onItemsChangeDuringSync(mutationEvents: [itemChange, itemChange2])
                } catch {
                    XCTFail("Failed to create post")
                }
            }
        }
        wait(for: [completeReceived], timeout: 10)
        sink.cancel()
    }

    /// When a predicate like `title.beginsWith("title")` is given, the models that matched the predicate
    /// should be added to the snapshots, like `post` and `post2`. When `post2.title` is updated to no longer
    /// match the predicate, it should be removed from the snapshot.
    func testUpdatedModelNoLongerMatchesPredicateRemovedFromSnapshot() throws {
        let firstSnapshot = expectation(description: "first query snapshots")
        let secondSnapshot = expectation(description: "second query snapshots")
        let thirdSnapshot = expectation(description: "third query snapshots")
        let fourthSnapshot = expectation(description: "fourth query snapshots")
        var querySnapshots = [DataStoreQuerySnapshot<Post>]()
        let operation = AWSDataStoreObserveQueryOperation(
            modelType: Post.self,
            modelSchema: Post.schema,
            predicate: Post.keys.title.beginsWith("title"),
            sortInput: QuerySortInput.ascending(Post.keys.id).asSortDescriptors(),
            storageEngine: storageEngine,
            dataStorePublisher: dataStorePublisher,
            dataStoreConfiguration: .default,
            dispatchedModelSyncedEvent: AtomicValue(initialValue: true))

        let sink = operation.publisher.sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("Failed with error \(error)")
            }
        } receiveValue: { querySnapshot in
            querySnapshots.append(querySnapshot)
            if querySnapshots.count == 1 {
                firstSnapshot.fulfill()
            } else if querySnapshots.count == 2 {
                secondSnapshot.fulfill()
            } else if querySnapshots.count == 3 {
                thirdSnapshot.fulfill()
            } else if querySnapshots.count == 4 {
                fourthSnapshot.fulfill()
            }
        }
        let queue = OperationQueue()
        queue.addOperation(operation)
        wait(for: [firstSnapshot], timeout: 5)

        let post = try createPost(id: "1", title: "title 1")
        dataStorePublisher.send(input: post)
        let post2 = try createPost(id: "2", title: "title 2")
        dataStorePublisher.send(input: post2)
        var updatedPost2 = try createPost(id: "2", title: "Does not match predicate")
        updatedPost2.mutationType = MutationEvent.MutationType.update.rawValue
        dataStorePublisher.send(input: updatedPost2)
        wait(for: [secondSnapshot, thirdSnapshot, fourthSnapshot], timeout: 10)
        XCTAssertEqual(querySnapshots.count, 4)

        // First snapshot is empty from the initial query
        XCTAssertEqual(querySnapshots[0].items.count, 0)

        // Second snapshot contains `post` since it matches the predicate
        XCTAssertEqual(querySnapshots[1].items.count, 1)
        XCTAssertEqual(querySnapshots[1].items[0].id, "1")

        // Third snapshot contains both posts since they both match the predicate
        XCTAssertEqual(querySnapshots[2].items.count, 2)
        XCTAssertEqual(querySnapshots[2].items[0].id, "1")
        XCTAssertEqual(querySnapshots[2].items[1].id, "2")

        // Fourth snapshot no longer has the post2 since it was updated to not match the predicate
        // and deleted at the same time.
        XCTAssertEqual(querySnapshots[3].items.count, 1)
        XCTAssertEqual(querySnapshots[3].items[0].id, "1")
        sink.cancel()
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
