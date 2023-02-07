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

extension AWSDataStoreLazyLoadCompositePKTests {
    
    // MARK: - CompositePKParent / StrangeExplicitChild
    
    func initStrangeExplicitChild(with parent: CompositePKParent) -> StrangeExplicitChild {
        StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initStrangeExplicitChild(with: savedParent)
        try await saveAndWaitForSync(child)
    }
    
    func testUpdateStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initStrangeExplicitChild(with: parent)
        var savedChild = try await saveAndWaitForSync(child)
        let loadedParent = try await savedChild.parent
        XCTAssertEqual(loadedParent.identifier, savedParent.identifier)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await saveAndWaitForSync(newParent)
        savedChild.setParent(savedNewParent)
        let updatedChild = try await updateAndWaitForSync(savedChild)
        let loadedNewParent = try await updatedChild.parent
        XCTAssertEqual(loadedNewParent.identifier, savedNewParent.identifier)
        
    }
    
    func testDeleteStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initStrangeExplicitChild(with: parent)
        let savedChild = try await saveAndWaitForSync(child)
        
        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testGetStrangeExplicitChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initStrangeExplicitChild(with: parent)
        let savedChild = try await saveAndWaitForSync(child)
        
        // query parent and load the children
        let queriedParent = try await query(for: savedParent)
        
        assertList(queriedParent.strangeChildren!, state: .isNotLoaded(associatedIds: [queriedParent.identifier],
                                                                       associatedFields: ["parent"]))
        try await queriedParent.strangeChildren?.fetch()
        assertList(queriedParent.strangeChildren!, state: .isLoaded(count: 1))
        
        // query children and load the parent - StrangeExplicitChild
        let queriedStrangeImplicitChild = try await query(for: savedChild)
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: savedParent.identifier)]))
        let loadedParent3 = try await queriedStrangeImplicitChild.parent
        assertLazyReference(queriedStrangeImplicitChild._parent,
                            state: .loaded(model: loadedParent3))
    }
}
