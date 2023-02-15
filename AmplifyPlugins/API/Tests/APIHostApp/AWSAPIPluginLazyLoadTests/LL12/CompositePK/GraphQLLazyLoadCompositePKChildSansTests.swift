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
    
    // MARK: - CompositePKParent / ChildSansBelongsTo
   
    func initChildSansBelongsTo(with parent: CompositePKParent) -> ChildSansBelongsTo {
        ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: parent.customId,
            compositePKParentChildrenSansBelongsToContent: parent.content)
    }
    
    func testSaveChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChildSansBelongsTo(with: savedParent)
        try await mutate(.create(child))
    }
    
    func testUpdateChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChildSansBelongsTo(with: parent)
        var savedChild = try await mutate(.create(child))
        XCTAssertEqual(savedChild.compositePKParentChildrenSansBelongsToCustomId, savedParent.customId)
        XCTAssertEqual(savedChild.compositePKParentChildrenSansBelongsToContent, savedParent.content)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.compositePKParentChildrenSansBelongsToCustomId = savedNewParent.customId
        savedChild.compositePKParentChildrenSansBelongsToContent = savedNewParent.content
        let updatedChild = try await mutate(.update(savedChild))
        XCTAssertEqual(updatedChild.compositePKParentChildrenSansBelongsToCustomId, savedNewParent.customId)
        XCTAssertEqual(updatedChild.compositePKParentChildrenSansBelongsToContent, savedNewParent.content)
    }
    
    func testDeleteChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChildSansBelongsTo(with: parent)
        let savedChild = try await mutate(.create(child))
 
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testGetChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChildSansBelongsTo(with: parent)
        let savedChild = try await mutate(.create(child))
        
        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        
        assertList(queriedParent.childrenSansBelongsTo!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                                     queriedParent.content],
                                                                             associatedFields: ["compositePKParentChildrenSansBelongsToCustomId", "compositePKParentChildrenSansBelongsToContent"]))
        try await queriedParent.childrenSansBelongsTo?.fetch()
        assertList(queriedParent.childrenSansBelongsTo!, state: .isLoaded(count: 1))
        
        // query children and verify the parent - ChildSansBelongsTo
        let queriedChildSansBelongsTo = try await query(.get(ChildSansBelongsTo.self,
                                                             byIdentifier: .identifier(childId: savedChild.childId,
                                                                                       content: savedChild.content)))!
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToCustomId, savedParent.customId)
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToContent, savedParent.content)
    }
    
    func testListChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChildSansBelongsTo(with: savedParent)
        try await mutate(.create(child))
        
        var queriedChild = try await listQuery(.list(ChildSansBelongsTo.self,
                                                     where: ChildSansBelongsTo.keys.childId == child.childId && ChildSansBelongsTo.keys.content == child.content))
        while queriedChild.hasNextPage() {
            queriedChild = try await queriedChild.getNextPage()
        }
        assertList(queriedChild, state: .isLoaded(count: 1))
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of ChildSansBelongsTo
        - Create new CompositePKParent instance with API
        - Create new ChildSansBelongsTo instance with API
     - Then:
        - the newly created instance is successfully created through API. onCreate event is received.
     */
    func testSubscribeChildSansBelongsToOnCreate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onCreate = asyncExpectation(description: "onCreate received")

        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = initChildSansBelongsTo(with: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ChildSansBelongsTo.self, type: .onCreate))
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
                        XCTFail("Failed to create ChildSansBelongsTo, error: \(error.errorDescription)")
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
        - Subscribe onCreate events of ChildSansBelongsTo
        - Create new CompositePKParent instance with API
        - Create new ChildSansBelongsTo instance with API
        - Update newly created ChildSansBelongsTo instance with API
     - Then:
        - the newly created instance is successfully updated through API. onUpdate event is received.
     */
    func testSubscribeChildSansBelongsToOnUpdate() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onUpdate = asyncExpectation(description: "onUpdate received")
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = initChildSansBelongsTo(with: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ChildSansBelongsTo.self, type: .onUpdate))
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
                        XCTFail("Failed to update ChildSansBelongsTo, error: \(error.errorDescription)")
                    default: ()
                    }
                }
            }
        }

        await waitForExpectations([connected], timeout: 10)
        try await mutate(.create(parent))
        try await mutate(.create(child))
        try await mutate(.update(child))
        await waitForExpectations([onUpdate], timeout: 10)
        subscription.cancel()
    }

    /*
     - Given: Api category setup with CompositePKModels
     - When:
        - Subscribe onCreate events of ChildSansBelongsTo
        - Create new CompositePKParent instance with API
        - Create new ChildSansBelongsTo instance with API
        - Delete newly created ChildSansBelongsTo with API
     - Then:
        - the newly created instance is successfully deleted through API. onDelete event is received.
     */
    func testSubscribeChildSansBelongsToOnDelete() async throws {
        await setup(withModels: CompositePKModels())
        let connected = asyncExpectation(description: "Subscription connected")
        let onDelete = asyncExpectation(description: "onUpdate received")
        let parent = CompositePKParent(customId: UUID().uuidString, content: UUID().uuidString)
        let child = initChildSansBelongsTo(with: parent)
        let subscription = Amplify.API.subscribe(request: .subscription(of: ChildSansBelongsTo.self, type: .onDelete))
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
                        XCTFail("Failed to update ChildSansBelongsTo, error: \(error.errorDescription)")
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
