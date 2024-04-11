//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
import AWSPluginsCore
@testable import Amplify
@testable import APIHostApp

final class GraphQLSubscriptionsTests: XCTestCase {
    static let amplifyConfiguration = "AWSAPIPluginV2Tests-amplifyconfiguration"
    
    override func setUp() async throws {
        await Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        
        let plugin = AWSAPIPlugin(modelRegistration: AmplifyModels())
        
        do {
            try Amplify.add(plugin: plugin)
            
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLSubscriptionsTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
            
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// Given: GraphQL onCreate subscription request with filter
    /// When: Adding models - one not matching and two matching the filter
    /// Then: Receive mutation syncs only for matching models
    func testOnCreatePostSubscriptionWithFilter() async throws {
        let incorrectTitle = "other_title"
        let incorrectPost1Id = UUID().uuidString
        
        let correctTitle = "correct"
        let correctPost1Id = UUID().uuidString
        let correctPost2Id = UUID().uuidString
        
        let connectedInvoked = expectation(description: "Connection established")
        let onCreateCorrectPost1 = expectation(description: "Receioved onCreate for correctPost1")
        let onCreateCorrectPost2 = expectation(description: "Receioved onCreate for correctPost2")
        
        let modelType = Post.self
        let filter: QueryPredicate = modelType.keys.title.eq(correctTitle)
        let request = GraphQLRequest<MutationSyncResult>.subscription(to: modelType, where: filter, subscriptionType: .onCreate)
        
        let subscription = Amplify.API.subscribe(request: request)
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let state):
                        switch state {
                        case .connected:
                            connectedInvoked.fulfill()
                            
                        case .connecting, .disconnected:
                            break
                        }
                        
                    case .data(let graphQLResponse):
                        switch graphQLResponse {
                        case .success(let mutationSync):
                            if mutationSync.model.id == correctPost1Id {
                                onCreateCorrectPost1.fulfill()
                                
                            } else if mutationSync.model.id == correctPost2Id {
                                onCreateCorrectPost2.fulfill()
                                
                            } else if mutationSync.model.id == incorrectPost1Id {
                                XCTFail("We should not receive onCreate for filtered out model!")
                            }
                            
                        case .failure(let error):
                            XCTFail(error.errorDescription)
                        }
                    }
                }
                
            } catch {
                XCTFail("Unexpected subscription failure: \(error)")
            }
        }
        
        await fulfillment(of: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        
        guard try await createPost(id: incorrectPost1Id, title: incorrectTitle) != nil else {
            XCTFail("Failed to create post"); return
        }
        
        guard try await createPost(id: correctPost1Id, title: correctTitle) != nil else {
            XCTFail("Failed to create post"); return
        }
        
        guard try await createPost(id: correctPost2Id, title: correctTitle) != nil else {
            XCTFail("Failed to create post"); return
        }
        
        await fulfillment(
            of: [onCreateCorrectPost1, onCreateCorrectPost2],
            timeout: TestCommonConstants.networkTimeout,
            enforceOrder: true
        )
        
        subscription.cancel()
    }

    // MARK: Helpers

    func createPost(id: String, title: String) async throws -> Post? {
        let post = Post(id: id, title: title, createdAt: .now())
        return try await createPost(post: post)
    }

    func createPost(post: Post) async throws -> Post? {
        let data = try await Amplify.API.mutate(request: .createMutation(of: post, version: 0))
        switch data {
        case .success(let post):
            return post.model.instance as? Post
        case .failure(let error):
            throw error
        }
    }
}
