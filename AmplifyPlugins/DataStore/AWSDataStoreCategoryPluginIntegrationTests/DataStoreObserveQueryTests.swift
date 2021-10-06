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

@available(iOS 13.0, *)
class DataStoreObserveQueryTests: SyncEngineIntegrationTestBase {

    /// ObserveQuery API will eventually return query snapshot with `isSynced` true
    ///
    /// - Given: DataStore is cleared
    /// - When:
    ///    - ObserveQuery API is called to start the sync engine
    /// - Then:
    ///    - Eventually one of the query snapshots will be returned with `isSynced` true
    ///
    func testObserveQueryWithIsSynced() throws {
        let started = expectation(description: "Amplify started")
        try startAmplify {
            started.fulfill()
        }
        wait(for: [started], timeout: 2)
        _ = Amplify.DataStore.clear()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")
        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                snapshotWithIsSynced.fulfill()
            }
        }

        _ = Amplify.DataStore.save(Post(title: "title", content: "content", createdAt: .now()))
        wait(for: [snapshotWithIsSynced], timeout: 100)
        sink.cancel()
    }

    /// A query snapshot with the recently saved post should be the last item when
    /// sort order is provided as ascending `createdAt`
    func testObserveQueryWithSort() throws {
        let started = expectation(description: "Amplify started")
        try startAmplify {
            started.fulfill()
        }
        wait(for: [started], timeout: 2)
        _ = Amplify.DataStore.clear()
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

        _ = Amplify.DataStore.save(post1)
        _ = Amplify.DataStore.save(post2)
        wait(for: [snapshotWithSavedPost], timeout: 100)
        sink.cancel()
    }

    ///  Ensure datastore is already in .ready state, observeQuery should return the first snapshot with isSynced true
    func testObserveQueryAfterDataStoreIsReady() throws {
        try startAmplifyAndWaitForReady()
        let snapshotWithIsSynced = expectation(description: "query snapshot with isSynced true")

        let sink = Amplify.DataStore.observeQuery(for: Post.self).sink { completed in
            switch completed {
            case .finished:
                break
            case .failure(let error):
                XCTFail("\(error)")
            }
        } receiveValue: { querySnapshot in
            if querySnapshot.isSynced {
                snapshotWithIsSynced.fulfill()
            }
        }
        wait(for: [snapshotWithIsSynced], timeout: 100)
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
}
