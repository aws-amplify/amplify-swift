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

extension GraphQLModelBasedTests {
    
    func testConcurrentSubscriptions() async throws {
        let count = 50
        let connectedInvoked = asyncExpectation(description: "Connection established", expectedFulfillmentCount: count)
        let disconnectedInvoked = asyncExpectation(description: "Connection disconnected", expectedFulfillmentCount: count)
        let completedInvoked = asyncExpectation(description: "Completed invoked", expectedFulfillmentCount: count)
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: count)

        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        let sequences = await withTaskGroup(of: AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<Post>>.self) { group -> [AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<Post>>] in
            for _ in 0..<count {
                group.addTask {
                    let subscription = Amplify.API.subscribe(request: .subscription(of: Post.self, type: .onCreate))
                    Task {
                        for try await subscriptionEvent in subscription {
                            switch subscriptionEvent {
                            case .connection(let state):
                                switch state {
                                case .connecting:
                                    break
                                case .connected:
                                    await connectedInvoked.fulfill()
                                case .disconnected:
                                    await disconnectedInvoked.fulfill()
                                }
                            case .data(let result):
                                switch result {
                                case .success(let post):
                                    if post.id == uuid {
                                        await progressInvoked.fulfill()
                                    }
                                case .failure(let error):
                                    XCTFail("\(error)")
                                }
                            }
                        }
                        await completedInvoked.fulfill()
                    }
                    return subscription
                }
            }
            
            var sequences = [AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<Post>>]()
            for await sequence in group {
                sequences.append(sequence)
            }
            return sequences
            
        }
    
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertEqual(sequences.count, count)
        
        guard try await createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        sequences.forEach { sequence in
            sequence.cancel()
        }
        await waitForExpectations([disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}
