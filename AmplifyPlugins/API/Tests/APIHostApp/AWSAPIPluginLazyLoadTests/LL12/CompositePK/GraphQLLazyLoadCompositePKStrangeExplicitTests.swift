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
    
    // MARK: - CompositePKParent / StrangeExplicitChild
    
    func initStrangeExplicitChild(with parent: CompositePKParent) -> StrangeExplicitChild {
        StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initStrangeExplicitChild(with: savedParent)
        try await mutate(.create(child))
    }
    
    func testUpdateStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initStrangeExplicitChild(with: parent)
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
    
    func testDeleteStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initStrangeExplicitChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testGetStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initStrangeExplicitChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        
        assertList(queriedParent.strangeChildren!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                               queriedParent.content],
                                                                       associatedFields: ["parent"]))
        try await queriedParent.strangeChildren?.fetch()
        assertList(queriedParent.strangeChildren!, state: .isLoaded(count: 1))
        
        // query children and load the parent - StrangeExplicitChild
        let queriedStrangeImplicitChild = try await query(.get(StrangeExplicitChild.self,
                                                           byIdentifier: .identifier(strangeId: savedChild.strangeId,
                                                                                     content: savedChild.content)))!
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent3 = try await queriedStrangeImplicitChild.parent
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .loaded(model: loadedParent3))
    }
    
    func testListStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initStrangeExplicitChild(with: savedParent)
        try await mutate(.create(child))
        
        var queriedChild = try await listQuery(
            .list(StrangeExplicitChild.self,
                  where: StrangeExplicitChild.keys.strangeId == child.strangeId && StrangeExplicitChild.keys.content == child.content))
        while queriedChild.hasNextPage() {
            queriedChild = try await queriedChild.getNextPage()
        }
        assertList(queriedChild, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of StrangeExplicitChild
        - Create new CompositePKParent instance with API
        - Create new StrangeExplicitChild instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeStrangeExplicitChildOnCreate() async throws {
        await setup(withModels: CompositePKModels())

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = StrangeExplicitChild(strangeId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let (onCreate, subscription) = try await subscribe(of: StrangeExplicitChild.self, type: .onCreate) { createdChild in
            createdChild.identifier == child.identifier
        }

        try await mutate(.create(parent))
        try await mutate(.create(child))
        await waitForExpectations([onCreate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of StrangeExplicitChild
        - Create new CompositePKParent instance with API
        - Create new StrangeExplicitChild instance with API
        - Update newly created StrangeExplicitChild instance with API
     - Then:
        - the newly created instance is successfully updated through API. onUpdate event is received.
     */
    func testSubscribeStrangeExplicitChildOnUpdate() async throws {
        await setup(withModels: CompositePKModels())

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = StrangeExplicitChild(strangeId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let (onUpdate, subscription) = try await subscribe(of: StrangeExplicitChild.self, type: .onUpdate, verifyChange: { updatedChild in
            let associatedParent = try await updatedChild.parent
            return associatedParent.identifier == parent.identifier
            && updatedChild.identifier == child.identifier
        })

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
        - Subscribe onCreate events of StrangeExplicitChild
        - Create new CompositePKParent instance with API
        - Create new StrangeExplicitChild instance with API
        - Delete newly created StrangeExplicitChild with API
     - Then:
        - the newly created instance is successfully deleted through API. onDelete event is received.
     */
    func testSubscribeStrangeExplicitChildOnDelete() async throws {
        await setup(withModels: CompositePKModels())

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = StrangeExplicitChild(strangeId: UUID().uuidString, content: UUID().uuidString, parent: parent)
        let (onDelete, subscription) = try await subscribe(of: StrangeExplicitChild.self, type: .onDelete) { deletedChild in
            deletedChild.identifier == child.identifier
        }

        try await mutate(.create(parent))
        try await mutate(.create(child))
        try await mutate(.delete(child))
        await waitForExpectations([onDelete], timeout: 10)
        subscription.cancel()
    }
}
