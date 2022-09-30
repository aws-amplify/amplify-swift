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
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let subscription = Amplify.API.subscribe(request: .subscription(of: Post3.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
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
            } catch {
                XCTFail("Unexpected subscription failure")
            }
        }
        
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let post = Post3(id: uuid, title: title)
        _ = try await Amplify.API.mutate(request: .create(post))
        let post2 = Post3(id: uuid2, title: title)
        _ = try await Amplify.API.mutate(request: .create(post2))

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    func testOnUpdatePostSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")

        let subscription = Amplify.API.subscribe(request: .subscription(of: Post3.self, type: .onUpdate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
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
            } catch {
                XCTFail("Unexpected subscription failure")
            }
        }
                                 
        await waitForExpectations([connectingInvoked, connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let post = Post3(id: uuid, title: title)
        _ = try await Amplify.API.mutate(request: .create(post))
        _ = try await Amplify.API.mutate(request: .update(post))

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
    }
    
    func testOnDeletePostSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")
        
        let subscription = Amplify.API.subscribe(request: .subscription(of: Post3.self, type: .onDelete))
        Task {
            do {
                for try await subscriptionEvent in subscription {
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
            } catch {
                XCTFail("Unexpected subscription failure")
            }
        }
        await waitForExpectations([connectingInvoked, connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let post = try await createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard try await deletePost(post: post) != nil else {
            XCTFail("Failed to update post")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testOnCreateCommentSubscriptionWithModel() async throws {
        let connectingInvoked = AsyncExpectation(description: "Connection connecting")
        let connectedInvoked = AsyncExpectation(description: "Connection established")
        let progressInvoked = AsyncExpectation(description: "progress invoked")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Comment3.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
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
            } catch {
                XCTFail("Unexpected subscription failure")
            }
        }
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let createdPost = try await createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard try await createComment(postID: createdPost.id, content: "content") != nil else {
            XCTFail("Failed to create comment with post")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}
