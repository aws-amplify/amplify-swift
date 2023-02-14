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

final class GraphQLLazyLoadDefaultPKTests: GraphQLLazyLoadBaseTest {

    func testConfigure() async throws {
        await setup(withModels: DefaultPKModels())
    }
    
    func testDefaultPKParentChild() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        assertLazyReference(savedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedParent.id)]))
        let loadedParent = try await savedChild.parent
        assertLazyReference(savedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultParentChildUpdate() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        var savedChild = try await mutate(.create(defaultPKChild))
        
        let newParent = DefaultPKParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.setParent(savedNewParent)
        var updatedChild = try await mutate(.update(savedChild))
                
        assertLazyReference(updatedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: newParent.id)]))
        let loadedParent = try await updatedChild.parent
        assertLazyReference(updatedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultParentChildDelete() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testDefaultPKParentChildGet() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        let queriedParent = try await query(.get(DefaultPKParent.self, byId: savedParent.id))!
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.id],
                                                                associatedFields: ["parent"]))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))
        
        let queriedChild = try await query(.get(DefaultPKChild.self, byId: savedChild.id))!
        assertLazyReference(queriedChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "id", value: savedParent.id)]))
        let loadedParent = try await queriedChild.parent
        assertLazyReference(queriedChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testDefaultPKParentChildList() async throws {
        await setup(withModels: DefaultPKModels())
        let defaultPKParent = DefaultPKParent()
        let savedParent = try await mutate(.create(defaultPKParent))
        let defaultPKChild = DefaultPKChild(parent: savedParent)
        let savedChild = try await mutate(.create(defaultPKChild))
        
        let queriedParents = try await listQuery(.list(DefaultPKParent.self,
                                                       where: DefaultPKParent.keys.id == defaultPKParent.id))
        assertList(queriedParents, state: .isLoaded(count: 1))
        
        let queriedChildren = try await listQuery(.list(DefaultPKChild.self,
                                                        where: DefaultPKChild.keys.id == defaultPKChild.id))
        assertList(queriedChildren, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onCreate events of DefaultPKChild
        - Create new DefaultPKChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeDefaultPKChildOnCreate() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")
        let child = DefaultPKChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKChild.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        if newModel.identifier == child.identifier {
                            await onCreate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to create DefaultPKChild, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onCreate events of DefaultPKParent
        - Create new DefaultPKChild and DefaultPKParent instances with API
     - Then:
        - the newly created parent is successfully created through API. onCreate event is received.
     */
    func testSubscribeDefaultPKParentOnCreate() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")
        let parent = DefaultPKParent()
        let child = DefaultPKChild(parent: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKParent.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        try await newModel.children?.fetch()
                        let associatedChilden = newModel.children?.loadedState
                        if newModel.identifier == parent.identifier,
                           case .some(.loaded(let associatedChilden)) = associatedChilden,
                           associatedChilden.map(\.identifier).contains(child.identifier)
                        {
                            await onCreate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to create DefaultPKParent, error: \(error.errorDescription)")
                    default: ()
                    }
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
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onUpdate events of DefaultPKChild
        - Create new DefaultPKChild instance with API
        - Update the newly created with API
     - Then:
        - an onUpdate event is received, the identifier is same to the updated one.
     */
    func testSubscriptionDefaultPKChildOnUpdate() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let child = DefaultPKChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKChild.self, type: .onUpdate))

        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        if newModel.identifier == child.identifier {
                            await onUpdate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to update DefaultPKChild, error: \(error.errorDescription)")
                    default: ()
                    }
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
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onUpdate events of HasOneParent
        - Create new DefaultPKChild instance with API
        - Create new DefaultPKParent instance with API
        - Update the newly created parent to another DefaultPKChild instance
     - Then:
        - an onUpdate event is received, the identifier is same to the updated one.
     */
    func testSubscriptionDefaultPKParentOnUpdate() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")

        let parent = DefaultPKParent()
        let child = DefaultPKChild(parent: parent)
        let anotherChild = DefaultPKChild(parent: parent)

        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKParent.self, type: .onUpdate))

        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        try await newModel.children?.fetch()
                        let associatedChilden = newModel.children?.loadedState
                        if newModel.identifier == parent.identifier,
                           case .some(.loaded(let associatedChilden)) = associatedChilden,
                           associatedChilden.map(\.identifier).contains(child.identifier),
                           associatedChilden.map(\.identifier).contains(anotherChild.identifier)
                        {
                            await onUpdate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to update HasOneParent, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(child))
        try await mutate(.create(parent))
        try await mutate(.create(anotherChild))
        var updatingParent = parent
        updatingParent.content = UUID().uuidString
        try await mutate(.update(updatingParent))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onDelete events of DefaultPKChild
        - Create new DefaultPKChild instance with API
        - Delete the newly created one with API
     - Then:
        - an onDelete event is received, the identifier is same to the newly created one.
     */
    func testSubscriptionDefaultPKChildOnDelete() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onDelete received")
        let child = DefaultPKChild()
        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKChild.self, type: .onDelete))

        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        if newModel.identifier == child.identifier {
                            await onDelete.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to delete DefaultPKChild, error: \(error.errorDescription)")
                    default: ()
                    }
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
     - Given: Api category setup with DefaultPKModels
     - When:
        - Subscribe onDelete events of DefaultPKParent
        - Create new DefaultPKChild instance with API
        - Create new DefaultPKParent instance with API
        - Delete the newly created parent with API
     - Then:
        - an onDelete event is received, the identifier is same to the newly created one.
     */
    func testSubscriptionDefaultPKParentOnDelete() async throws {
        await setup(withModels: DefaultPKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onDelete received")
        let parent = DefaultPKParent()
        let child = DefaultPKChild(parent: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: DefaultPKParent.self, type: .onDelete))

        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        try await newModel.children?.fetch()
                        let associatedChilden = newModel.children?.loadedState
                        if newModel.identifier == parent.identifier,
                           case .some(.loaded(let associatedChildren)) = associatedChilden,
                           associatedChildren.map(\.identifier).contains(child.identifier)
                        {
                            await onDelete.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to delete DefaultPKParent, error: \(error.errorDescription)")
                    default: ()
                    }
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

extension GraphQLLazyLoadDefaultPKTests: DefaultLogger { }

extension GraphQLLazyLoadDefaultPKTests {
    
    struct DefaultPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: DefaultPKParent.self)
            ModelRegistry.register(modelType: DefaultPKChild.self)
        }
    }
}
