//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class AWSDataStorePluginSubscribeBehaviorTests: BaseDataStoreTests {

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

        wait(for: [snapshotReceived], timeout: 3)
        sink.cancel()

    }
}
