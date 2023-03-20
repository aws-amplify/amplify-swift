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

    // MARK: - CompositePKParent / CompositePKChild
    
    func initChild(with parent: CompositePKParent? = nil) -> CompositePKChild {
        CompositePKChild(childId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: savedParent)
        try await mutate(.create(child))
    }
    
    func testUpdateCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        var savedChild = try await mutate(.create(child))
        let loadedParent = try await savedChild.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await mutate(.create(newParent))
        savedChild.setParent(savedNewParent)
        let updatedChild = try await mutate(.update(savedChild))
        let loadedNewParent = try await updatedChild.parent
        XCTAssertEqual(loadedNewParent?.identifier, savedNewParent.identifier)
    }
    
    func testUpdateFromNoParentCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        
        let childWithoutParent = initChild()
        var savedChild = try await mutate(.create(childWithoutParent))
        let nilParent = try await savedChild.parent
        XCTAssertNil(nilParent)
        
        // update the child to a parent
        savedChild.setParent(savedParent)
        let savedChildWithParent = try await mutate(.update(savedChild))
        let loadedParent = try await savedChildWithParent.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
    }
    
    func testDeleteCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        let savedChild = try await mutate(.create(child))
        
        try await mutate(.delete(savedParent))
        try await assertModelDoesNotExist(savedParent)
        try await mutate(.delete(savedChild))
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testGetCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())

        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: parent)
        let savedCompositePKChild = try await mutate(.create(child))

        // query parent and load the children
        let queriedParent = try await query(.get(CompositePKParent.self,
                                                 byIdentifier: .identifier(customId: savedParent.customId,
                                                                           content: savedParent.content)))!
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIdentifiers: [queriedParent.customId,
                                                                                        queriedParent.content],
                                                                associatedFields: ["parent"]))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))

        // query child and load the parent - CompositePKChild
        let queriedCompositePKChild = try await query(.get(CompositePKChild.self,
                                                           byIdentifier: .identifier(childId: savedCompositePKChild.childId,
                                                                                     content: savedCompositePKChild.content)))!
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "customId", value: savedParent.customId),
                                                            .init(name: "content", value: savedParent.content)]))
        let loadedParent = try await queriedCompositePKChild.parent
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .loaded(model: loadedParent))
    }

    func testListCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await mutate(.create(parent))
        let child = initChild(with: savedParent)
        try await mutate(.create(child))

        var queriedChild = try await listQuery(.list(CompositePKChild.self,
                                                     where: CompositePKChild.keys.childId == child.childId))
        while queriedChild.hasNextPage() {
            queriedChild = try await queriedChild.getNextPage()
        }
        assertList(queriedChild, state: .isLoaded(count: 1))
    }
}
