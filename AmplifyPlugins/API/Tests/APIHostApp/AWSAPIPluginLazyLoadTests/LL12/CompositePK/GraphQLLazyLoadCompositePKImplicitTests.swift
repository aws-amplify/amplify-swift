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

extension GraphQLLazyLoadCompositePKTests {
    
    // MARK: - CompositePKParent / ImplicitChild
    
    func initImplicitChild(with parent: CompositePKParent) -> ImplicitChild {
        ImplicitChild(childId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveImplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initImplicitChild(with: savedParent)
        try await mutate(.create(child))
    }
    
    func testUpdateImplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initImplicitChild(with: parent)
        var savedChild = try await mutate(.create(child))
        let loadedParent = try await savedChild.parent
        XCTAssertEqual(loadedParent.identifier, savedParent.identifier)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.setParent(savedNewParent)
        let updatedChild = try await mutate(.update(savedChild))
        let loadedNewParent = try await updatedChild.parent
        XCTAssertEqual(loadedNewParent.identifier, savedNewParent.identifier)
        
    }
    
    func testDeleteImplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initImplicitChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testGetImplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initImplicitChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        
        assertList(queriedParent.implicitChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                                queriedParent.content],
                                                                        associatedFields: ["parent"]))
        try await queriedParent.implicitChildren?.fetch()
        assertList(queriedParent.implicitChildren!, state: .isLoaded(count: 1))

       
        // query child and load the parent - ImplicitChild
        let queriedImplicitChild = try await query(.get(ImplicitChild.self,
                                                        byIdentifier: .identifier(childId: savedChild.childId,
                                                                                  content: savedChild.content)))!
        assertLazyReference(queriedImplicitChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent = try await queriedImplicitChild.parent
        assertLazyReference(queriedImplicitChild._parent,
                            state: .loaded(model: loadedParent))
    }
    
    func testListImplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initImplicitChild(with: savedParent)
        try await mutate(.create(child))
        
        var queriedChild = try await listQuery(
            .list(ImplicitChild.self,
                  where: ImplicitChild.keys.childId == child.childId && ImplicitChild.keys.content == child.content))
        while queriedChild.hasNextPage() {
            queriedChild = try await queriedChild.getNextPage()
        }
        assertList(queriedChild, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of ImplicitChild
        - Create new CompositePKParent instance with API
        - Create new ImplicitChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeImplicitChildOnCreate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = ImplicitChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ImplicitChild.self, type: .onCreate))
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
                        XCTFail("Failed to create CompositePKChild, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(parent))
        try await mutate(.create(child))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of ImplicitChild
        - Create new CompositePKParent instance with API
        - Create new ImplicitChild instance with API
        - Update newly created ImplicitChild instance with API
     - Then:
        - the newly created instance is successfully updated through API. onUpdate event is received.
     */
    func testSubscribeImplicitChildOnUpdate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = ImplicitChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ImplicitChild.self, type: .onUpdate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(.connected):
                        await connected.fulfill()
                    case let .data(.success(newModel)):
                        let associatedParent = try await newModel.parent
                        if newModel.identifier == child.identifier,
                           associatedParent.identifier == parent.identifier
                        {
                            await onUpdate.fulfill()
                        }
                    case let .data(.failure(error)):
                        XCTFail("Failed to update CompositePKParent, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(parent))
        try await mutate(.create(child))

        var updatingChild = child
        updatingChild.setParent(parent)
        try await mutate(.update(updatingChild))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of CompositePKChild
        - Create new CompositePKParent instance with API
        - Create new CompositePKChild instance with API
        - Delete newly created CompositePKChild with API
     - Then:
        - the newly created instance is successfully deleted through API. onDelete event is received.
     */
    func testSubscribeImplicitChildOnDelete() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onUpdate received")
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = ImplicitChild(childId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ImplicitChild.self, type: .onDelete))
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
                        XCTFail("Failed to update CompositePKParent, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(parent))
        try await mutate(.create(child))
        try await mutate(.delete(child))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
    }
}
