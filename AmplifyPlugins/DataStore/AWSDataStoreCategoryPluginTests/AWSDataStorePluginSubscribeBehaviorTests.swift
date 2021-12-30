//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class AWSDataStorePluginSubscribeBehaviorTests: BaseDataStoreTests {

    /// Calling the observeQuery API will eventually return a snapshot as it internally performs an initial query to SQL
    func testObserveQuery() throws {
        let snapshotReceived = expectation(description: "query snapshot received")
        let predicate = Post.keys.content.contains("someValue")
        let sink = Amplify.DataStore.observeQuery(for: Post.self,
                                                  where: predicate,
                                                  sort: .ascending(Post.keys.createdAt))
            .sink { completed in
                switch completed {
                case .finished:
                    break
                case .failure(let error):
                    XCTFail("\(error)")
                }
            } receiveValue: { _ in
                snapshotReceived.fulfill()
            }

        wait(for: [snapshotReceived], timeout: 20)
        sink.cancel()
    }

    func testObserveQueryResetAfterDataStoreStop() {
        let snapshotReceived = expectation(description: "query snapshot received")

        let sink = dataStorePlugin.observeQuery(for: Post.self).sink { completion in
            switch completion {
            case .finished:
                XCTFail("ObserveQueries should not be completed")
            case .failure(let error):
                XCTFail("\(error.localizedDescription)")
            }
        } receiveValue: { _ in
            snapshotReceived.fulfill()
        }
        wait(for: [snapshotReceived], timeout: 3)

        XCTAssertEqual(dataStorePlugin.operationQueue.operations.count, 1)

        guard let operation = dataStorePlugin.operationQueue.operations.first,
              let observeQueryOperation = operation as? AWSDataStoreObserveQueryOperation<Post> else {
            XCTFail("Couldn't get observe query operation")
            return
        }
        XCTAssertTrue(observeQueryOperation.observeQueryStarted)

        let dataStoreStopSuccess = expectation(description: "Stop successfully")
        dataStorePlugin.stop { result in
            switch result {
            case .success:
                dataStoreStopSuccess.fulfill()
            case .failure(let error):
                XCTFail("\(error.localizedDescription)")
            }
        }

        wait(for: [dataStoreStopSuccess], timeout: 1)

        XCTAssertEqual(dataStorePlugin.operationQueue.operations.count, 1)
        XCTAssertFalse(observeQueryOperation.observeQueryStarted)
        sink.cancel()
    }

    func testObserveQueryFailOnMissingDispatchedModelSyncedEvent() {
        dataStorePlugin.dispatchedModelSyncedEvents[Post.modelName] = nil
        let failReceived = expectation(description: "ObserveQuery failure received")
        let sink = Amplify.DataStore.observeQuery(for: Post.self)
            .sink { completed in
                switch completed {
                case .finished:
                    break
                case .failure(let error):
                    guard case .unknown = error else {
                        XCTFail("Expected to be `unknown` error")
                        return
                    }
                    failReceived.fulfill()
                }
            } receiveValue: { _ in }

        wait(for: [failReceived], timeout: 3)
        sink.cancel()
    }
}
