//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStorePlugin

final class IncomingAsyncSubscriptionEventPublisherTests: XCTestCase {
    var apiPlugin: MockAPICategoryPlugin!
    override func setUp() {
        apiPlugin = MockAPICategoryPlugin()
        ModelRegistry.register(modelType: Post.self)
    }

    /// This test was written to to reproduce a bug where the subscribe would miss events emitted by the publisher.
    /// The pattern in this test using the publisher (`IncomingAsyncSubscriptionEventPublisher`) and subscriber
    /// (`IncomingAsyncSubscriptionEventToAnyModelMapper`) are identical to the usage in `AWSModelReconciliationQueue.init()`.
    ///
    /// See the changes in this PR: https://github.com/aws-amplify/amplify-swift/pull/3489
    ///
    /// Before the PR changes, the publisher would emit events concurrently which caused some of them to be missed
    /// by the subscriber even though the subscriber applied back pressure to process one event at a time (demand
    /// of `max(1)`). For more details regarding back-pressure, see
    /// https://developer.apple.com/documentation/combine/processing-published-elements-with-subscribers
    ///
    /// The change, to publish the events though the same TaskQueue ensures that the events are properly buffered
    /// and sent only when the subscriber demands for it.
    func testSubscriberRecievedEvents() async throws {
        let expectedEvents = expectation(description: "Expected number of ")
        let numberOfEvents = 50
        expectedEvents.expectedFulfillmentCount = numberOfEvents
        let asyncEvents = await IncomingAsyncSubscriptionEventPublisher(
            modelSchema: Post.schema,
            api: apiPlugin,
            modelPredicate: nil,
            auth: nil,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            awsAuthService: nil)
        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        asyncEvents.subscribe(subscriber: mapper)
        let sink = mapper
            .publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in
                    expectedEvents.fulfill()
                }
            )
        DispatchQueue.concurrentPerform(iterations: numberOfEvents) { index in
            asyncEvents.send(.connection(.connected))
        }

        await fulfillment(of: [expectedEvents], timeout: 2)
        sink.cancel()
    }

    /// Ensure that the publisher-subscriber with back pressure is receiving all the events in the order in which they were sent.
    func testSubscriberRecievedEventsInOrder() async throws {
        let expectedEvents = expectation(description: "Expected number of ")
        let expectedOrder = AtomicValue<[String]>(initialValue: [])
        let actualOrder = AtomicValue<[String]>(initialValue: [])
        let numberOfEvents = 50
        expectedEvents.expectedFulfillmentCount = numberOfEvents
        let asyncEvents = await IncomingAsyncSubscriptionEventPublisher(
            modelSchema: Post.schema,
            api: apiPlugin,
            modelPredicate: nil,
            auth: nil,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            awsAuthService: nil)
        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        asyncEvents.subscribe(subscriber: mapper)
        let sink = mapper
            .publisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    switch event {
                    case .payload(let mutationSync):
                        actualOrder.append(mutationSync.syncMetadata.modelId)
                    default:
                        break
                    }
                    expectedEvents.fulfill()
                }
            )

        for index in 0..<numberOfEvents {
            let post = Post(id: "\(index)", title: "title", content: "content", createdAt: .now())
            expectedOrder.append(post.id)
            asyncEvents.send(.data(.success(.init(model: AnyModel(post),
                                                  syncMetadata: .init(modelId: post.id,
                                                                      modelName: "Post",
                                                                      deleted: false,
                                                                      lastChangedAt: 0,
                                                                      version: 0)))))
        }

        await fulfillment(of: [expectedEvents], timeout: 2)
        XCTAssertEqual(expectedOrder.get(), actualOrder.get())
        sink.cancel()
    }
    
    /// Given: IncomingAsyncSubscriptionEventPublisher initilized with modelPredicate
    /// When: IncomingAsyncSubscriptionEventPublisher subscribes to onCreate, onUpdate, onDelete events
    /// Then: IncomingAsyncSubscriptionEventPublisher provides correct filters in subscriptions request
    func testModelPredicateAsSubscribtionsFilter() async throws {
        
        let id1 = UUID().uuidString
        let id2 = UUID().uuidString
        
        let correctFilterOnCreate = expectation(description: "Correct filter in onCreate request")
        let correctFilterOnUpdate = expectation(description: "Correct filter in onUpdate request")
        let correctFilterOnDelete = expectation(description: "Correct filter in onDelete request")
        
        func validateVariables(_ variables: [String: Any]?) -> Bool {
            guard let variables = variables else {
                XCTFail("The request doesn't contain variables")
                return false
            }
            
            guard
                let filter = variables["filter"] as? [String: [[String: [String: String]]]],
                filter == ["or": [
                    ["id": ["eq": id1]],
                    ["id": ["eq": id2]]
                ]]
                    
            else {
                XCTFail("The document variables property doesn't contain a valid filter")
                return false
            }

            return true
        }
        
        let responder = SubscribeRequestListenerResponder<MutationSync<AnyModel>> { request, _, _ in
            if request.document.contains("onCreatePost") {
                if validateVariables(request.variables) {
                    correctFilterOnCreate.fulfill()
                }
                
            } else if request.document.contains("onUpdatePost") {
                if validateVariables(request.variables) {
                    correctFilterOnUpdate.fulfill()
                }
                
            } else if request.document.contains("onDeletePost") {
                if validateVariables(request.variables) {
                    correctFilterOnDelete.fulfill()
                }
                
            } else {
                XCTFail("Unexpected request: \(request.document)")
            }
            
            return nil
        }

        apiPlugin.responders[.subscribeRequestListener] = responder
        
        _ = await IncomingAsyncSubscriptionEventPublisher(
            modelSchema: Post.schema,
            api: apiPlugin,
            modelPredicate: QueryPredicateGroup(type: .or, predicates: [
                Post.keys.id.eq(id1),
                Post.keys.id.eq(id2)
            ]),
            auth: nil,
            authModeStrategy: AWSDefaultAuthModeStrategy(),
            awsAuthService: nil)

        await fulfillment(of: [correctFilterOnCreate, correctFilterOnUpdate, correctFilterOnDelete], timeout: 1)
    }
}
