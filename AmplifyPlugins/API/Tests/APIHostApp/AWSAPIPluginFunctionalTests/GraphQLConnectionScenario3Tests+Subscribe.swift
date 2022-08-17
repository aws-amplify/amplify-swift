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

    func testOnCreatePostSubscriptionWithModel() async throws {
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let task = try await Amplify.API.subscribe(request: .subscription(of: Post3.self, type: .onCreate))
        let subscription = await task.subscription
        Task {
            for await subscriptionEvent in subscription {
                switch subscriptionEvent {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        break
                    }
                case .data(let result):
                    switch result {
                    case .success(let post):
                        if post.id == uuid || post.id == uuid2 {
                            
                            await progressInvoked.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            }
        }
        
        XCTAssertNotNil(task)
        try await AsyncExpectation.waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let post = Post3(id: uuid, title: title)
        _ = try await Amplify.API.mutate(request: .create(post))
        let post2 = Post3(id: uuid2, title: title)
        _ = try await Amplify.API.mutate(request: .create(post2))

        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        await task.cancel()
    }
    
    func testOnUpdatePostSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")

        let task = try await Amplify.API.subscribe(request: .subscription(of: Post3.self, type: .onUpdate))
        let subscription = await task.subscription
        Task {
            for await subscriptionEvent in subscription {
                switch subscriptionEvent {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        await connectingInvoked.fulfill()
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        break
                    }
                case .data:
                    await progressInvoked.fulfill()
                }
            }
        }
                                 
        try await AsyncExpectation.waitForExpectations([connectingInvoked, connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post3(id: uuid, title: title)
        _ = try await Amplify.API.mutate(request: .create(post))
        _ = try await Amplify.API.mutate(request: .update(post))

        try await AsyncExpectation.waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)

        await task.cancel()
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
