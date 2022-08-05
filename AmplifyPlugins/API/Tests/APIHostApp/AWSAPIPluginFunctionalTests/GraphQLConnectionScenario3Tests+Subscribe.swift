//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

extension GraphQLConnectionScenario3Tests {

    func testOnCreatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Post3.self, type: .onCreate),
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
                        if post.id == uuid || post.id == uuid2 {
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

        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        guard createPost(id: uuid2, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnUpdatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Post3.self, type: .onUpdate),
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
                case .data:
                    progressInvoked.fulfill()
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
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }
        guard mutatePost(post: createdPost) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnDeletePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Post3.self, type: .onDelete),
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
                case .data:
                    progressInvoked.fulfill()
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
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard deletePost(post: post) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnCreateCommentSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Comment3.self, type: .onCreate),
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
                case .data:
                    progressInvoked.fulfill()
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
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard createComment(postID: createdPost.id, content: "content") != nil else {
            XCTFail("Failed to create comment with post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }
}
