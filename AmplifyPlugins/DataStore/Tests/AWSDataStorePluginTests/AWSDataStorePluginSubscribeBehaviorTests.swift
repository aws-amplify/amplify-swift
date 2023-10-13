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
        let subscription = Amplify.DataStore.observeQuery(for: Post.self,
                                                  where: predicate,
                                                  sort: .ascending(Post.keys.createdAt))
        let sink = Amplify.Publisher.create(subscription)
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

    func testObserveQueryFailOnMissingDispatchedModelSyncedEvent() throws {
        dataStorePlugin.dispatchedModelSyncedEvents[Post.modelName] = nil
        try XCTAssertThrowFatalError {
            _ = Amplify.DataStore.observeQuery(for: Post.self)
        }
    }
}
