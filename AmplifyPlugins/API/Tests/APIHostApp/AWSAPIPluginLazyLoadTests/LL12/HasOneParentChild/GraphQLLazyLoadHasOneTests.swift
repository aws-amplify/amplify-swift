//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify
import AWSPluginsCore

final class GraphQLLazyLoadHasOneTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: HasOneParentChildModels())
    }
    
    func testHasOneParentChild() async throws {
        await setup(withModels: HasOneParentChildModels())
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        assertLazyReference(savedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedChild.id)]))
        let loadedChild = try await savedParent.child
        assertLazyReference(savedParent._child,
                            state: .loaded(model: loadedChild))
    }
    
    func testHasOneParentChildUpdate() async throws {
        await setup(withModels: HasOneParentChildModels())
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        var savedParent = try await mutate(.create(hasOneParent))
        
        let newChild = HasOneChild()
        let savedNewChild = try await mutate(.create(newChild))
        savedParent.setChild(newChild)
        var updatedParent = try await mutate(.update(savedParent))
        
        assertLazyReference(updatedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: newChild.id)]))
        let loadedChild = try await updatedParent.child
        assertLazyReference(updatedParent._child,
                            state: .loaded(model: loadedChild))
    }
    
    func testHasOneParentChildDelete() async throws {
        await setup(withModels: HasOneParentChildModels())
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        var savedParent = try await mutate(.create(hasOneParent))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testHasOneParentChildGet() async throws {
        await setup(withModels: HasOneParentChildModels())
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        let queriedParent = try await query(.get(HasOneParent.self, byId: savedParent.id))!
        assertLazyReference(queriedParent._child,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedChild.id)]))
        let loadedChild = try await queriedParent.child
        assertLazyReference(queriedParent._child,
                            state: .loaded(model: loadedChild))
        
        let queriedChild = try await query(.get(HasOneChild.self, byId: savedChild.id))!
    }
    
    func testHasOneParentChildList() async throws {
        await setup(withModels: HasOneParentChildModels())
        let hasOneChild = HasOneChild()
        let savedChild = try await mutate(.create(hasOneChild))
        let hasOneParent = HasOneParent(child: hasOneChild)
        let savedParent = try await mutate(.create(hasOneParent))
        
        let queriedParents = try await listQuery(.list(HasOneParent.self,
                                                       where: HasOneParent.keys.id == hasOneParent.id))
        assertList(queriedParents, state: .isLoaded(count: 1))
        
        let queriedChildren = try await listQuery(.list(HasOneChild.self,
                                                       where: HasOneChild.keys.id == hasOneChild.id))
        assertList(queriedChildren, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onCreate events of HasOneChild
        - Create new HasOneChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeHasOneChildOnCreate() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")
        let child = HasOneChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneChild.self, type: .onCreate))
        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to create HasOneChild, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == child.identifier
                {
                    await onCreate.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onCreate events of HasOneParent
        - Create new HasOneChild and HasOneParent instances with API
     - Then:
        - the newly created parent is successfully created through API. onCreate event is received.
     */
    func testSubscribeHasOneParentOnCreate() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")
        let child = HasOneChild()
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneParent.self, type: .onCreate))
        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to create HasOneParent, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == parent.identifier,
                   let associatedChild = try await data.child,
                   associatedChild.identifier == child.identifier
                {
                    await onCreate.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.create(parent))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onUpdate events of HasOneChild
        - Create new HasOneChild instance with API
        - Update the newly created with API
     - Then:
        - an onUpdate event is received, the identifier is same to the updated one.
     */
    func testSubscriptionHasOnChildOnUpdate() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let child = HasOneChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneChild.self, type: .onUpdate))

        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to update HasOneChild, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == child.identifier
                {
                    await onUpdate.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        var updatingChild = child
        updatingChild.content = UUID().uuidString
        try await mutate(.update(updatingChild))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onUpdate events of HasOneParent
        - Create new HasOneChild instance with API
        - Create new HasOneParent instance with API
        - Update the newly created parent to another HasOneChild instance
     - Then:
        - an onUpdate event is received, the identifier is same to the updated one.
     */
    func testSubscriptionHasOnParentOnUpdate() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let child = HasOneChild()
        let anotherChild = HasOneChild()
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneParent.self, type: .onUpdate))

        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to update HasOneParent, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == parent.identifier,
                   let associatedChild = try await data.child,
                   associatedChild.identifier == anotherChild.identifier
                {
                    await onUpdate.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.create(parent))
        var updatingParent = parent
        updatingParent.setChild(anotherChild)
        updatingParent.hasOneParentChildId = anotherChild.id
        try await mutate(.create(anotherChild))
        try await mutate(.update(updatingParent))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onDelete events of HasOneChild
        - Create new HasOneChild instance with API
        - Delete the newly created one with API
     - Then:
        - an onDelete event is received, the identifier is same to the newly created one.
     */
    func testSubscriptionHasOneChildOnDelete() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onDelete received")
        let child = HasOneChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneChild.self, type: .onDelete))

        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to delete HasOneChild, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == child.identifier
                {
                    await onDelete.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.delete(child))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with HasOneParentChildModels
     - When:
        - Subscribe onDelete events of HasOneParent
        - Create new HasOneChild instance with API
        - Create new HasOneParent instance with API
        - Delete the newly created parent with API
     - Then:
        - an onDelete event is received, the identifier is same to the newly created one.
     */
    func testSubscriptionHasOneParentOnDelete() async throws {
        await setup(withModels: HasOneParentChildModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onDelete received")
        let child = HasOneChild()
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        let subscription = Amplify.API.subscribe(request: .subscription(of: HasOneParent.self, type: .onDelete))

        Task {
            for try await subscriptionEvent in subscription {
                if subscriptionEvent.isConnected() {
                    await connected.fulfill()
                }

                if let error = subscriptionEvent.extractError() {
                    XCTFail("Failed to delete HasOneParent, error: \(error.errorDescription)")
                }

                if let data = subscriptionEvent.extractData(),
                   data.identifier == parent.identifier,
                   let associatedChild = try await data.child,
                   associatedChild.identifier == child.identifier
                {
                    await onDelete.fulfill()
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.create(parent))
        try await mutate(.delete(parent))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
    }
}

extension GraphQLLazyLoadHasOneTests: DefaultLogger { }

extension GraphQLLazyLoadHasOneTests {
    
    struct HasOneParentChildModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: HasOneParent.self)
            ModelRegistry.register(modelType: HasOneChild.self)
        }
    }
}
