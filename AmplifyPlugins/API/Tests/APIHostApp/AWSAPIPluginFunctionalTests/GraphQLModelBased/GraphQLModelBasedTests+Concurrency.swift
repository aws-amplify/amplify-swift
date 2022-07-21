//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

extension GraphQLModelBasedTests {

    func testConcurrentSubscriptions() throws {
        let count = 50
        let connectedInvoked = expectation(description: "Connection established")
        connectedInvoked.expectedFulfillmentCount = count
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        disconnectedInvoked.expectedFulfillmentCount = count
        let completedInvoked = expectation(description: "Completed invoked")
        completedInvoked.expectedFulfillmentCount = count
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = count
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        let operations = AtomicValue<[GraphQLSubscriptionOperation<Post>]>(initialValue: [])
        DispatchQueue.concurrentPerform(iterations: count) { _ in
            let operation = Amplify.API.subscribe(
                request: .subscription(of: Post.self, type: .onCreate),
                valueListener: { event in
                    switch event {
                    case .connection(let state):
                        switch state {
                        case .connecting:
                            break
                        case .connected:
                            connectedInvoked.fulfill()
                        case .disconnected:
                            disconnectedInvoked.fulfill()
                        }
                    case .data(let result):
                        switch result {
                        case .success(let post):
                            if post.id == uuid {
                                progressInvoked.fulfill()
                            }
                        case .failure(let error):
                            XCTFail("\(error)")
                        }
                    }

            },
                completionListener: { event in
                    switch event {
                    case .failure(let error):
                        XCTFail("Unexpected .failed event: \(error)")
                    case .success:
                        completedInvoked.fulfill()
                    }
            })
            operations.append(operation)
        }

        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertEqual(operations.get().count, count)
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        DispatchQueue.concurrentPerform(iterations: count) { index in
            operations.get()[index].cancel()
        }
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)

        let completedOperations = operations.get()
        for operation in completedOperations {
            XCTAssertTrue(operation.isFinished)
        }
    }
}
