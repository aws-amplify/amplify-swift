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
    
    // MARK: - CompositePKParent / CompositePKChild
    
    func initChild(with parent: CompositePKParent? = nil) -> CompositePKChild {
        CompositePKChild(childId: UUID().uuidString, content: "content", parent: parent)
    }
    
    func testSaveCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initChild(with: savedParent)
        try await saveAndWaitForSync(child)
    }
    
    func testUpdateCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initChild(with: parent)
        var savedChild = try await saveAndWaitForSync(child)
        let loadedParent = try await savedChild.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await saveAndWaitForSync(newParent)
        savedChild.setParent(savedNewParent)
        let updatedChild = try await updateAndWaitForSync(savedChild)
        let loadedNewParent = try await updatedChild.parent
        XCTAssertEqual(loadedNewParent?.identifier, savedNewParent.identifier)
    }
    
    func testUpdateFromNoParentCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        
        let childWithoutParent = initChild()
        var savedChild = try await saveAndWaitForSync(childWithoutParent)
        let nilParent = try await savedChild.parent
        XCTAssertNil(nilParent)
        
        // update the child to a parent
        savedChild.setParent(savedParent)
        let savedChildWithParent = try await updateAndWaitForSync(savedChild)
        let loadedParent = try await savedChildWithParent.parent
        XCTAssertEqual(loadedParent?.identifier, savedParent.identifier)
    }
    
    func testDeleteCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initChild(with: parent)
        let savedChild = try await saveAndWaitForSync(child)
        
        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
        try await assertModelDoesNotExist(savedChild)
    }
    
    func testGetCompositePKChild() async throws {
        await setup(withModels: CompositePKModels())
        
        let parent = initParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = initChild(with: parent)
        let savedCompositePKChild = try await saveAndWaitForSync(child)
        
        // query parent and load the children
        let queriedParent = try await query(for: savedParent)
        assertList(queriedParent.children!, state: .isNotLoaded(associatedIds: [queriedParent.identifier],
                                                                associatedFields: ["parent"]))
        try await queriedParent.children?.fetch()
        assertList(queriedParent.children!, state: .isLoaded(count: 1))
        
        // query child and load the parent - CompositePKChild
        let queriedCompositePKChild = try await query(for: savedCompositePKChild)
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .notLoaded(identifiers: [.init(name: "@@primaryKey", value: savedParent.identifier)]))
        let loadedParent = try await queriedCompositePKChild.parent
        assertLazyReference(queriedCompositePKChild._parent,
                            state: .loaded(model: loadedParent))
    }
}
