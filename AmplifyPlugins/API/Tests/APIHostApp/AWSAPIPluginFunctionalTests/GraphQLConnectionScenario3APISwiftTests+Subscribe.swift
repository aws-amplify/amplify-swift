//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

extension GraphQLConnectionScenario3Tests {
    
    func onCreatePost3APISwiftRequest() -> GraphQLRequest<APISwift.OnCreatePost3Subscription.Data> {
        let request = GraphQLRequest<APISwift.OnCreatePost3Subscription.Data>(
            document: APISwift.OnCreatePost3Subscription.operationString,
            responseType: APISwift.OnCreatePost3Subscription.Data.self)
        return request
    }
    
    func createPost3APISwift(_ id: String, _ title: String) async throws -> APISwift.CreatePost3Mutation.Data.CreatePost3? {
        let input = APISwift.CreatePost3Input(id: id, title: title)
        let mutation = APISwift.CreatePost3Mutation(input: input)
        let request = GraphQLRequest<APISwift.CreatePost3Mutation.Data>(
            document: APISwift.CreatePost3Mutation.operationString,
            variables: mutation.variables?.jsonObject,
            responseType: APISwift.CreatePost3Mutation.Data.self)
        let response = try await Amplify.API.mutate(request: request)
        switch response {
        case .success(let data):
            return data.createPost3
        case .failure(let error):
            throw error
        }
    }
    
    func testOnCreateSubscriptionAPISwift() async throws {
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        let subscription = Amplify.API.subscribe(request: onCreatePost3APISwiftRequest())
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
                        case .success(let data):
                            if data.onCreatePost3?.id == uuid || data.onCreatePost3?.id == uuid2 {
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
        guard try await createPost3APISwift(uuid, title) != nil,
              try await createPost3APISwift(uuid2, title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}
