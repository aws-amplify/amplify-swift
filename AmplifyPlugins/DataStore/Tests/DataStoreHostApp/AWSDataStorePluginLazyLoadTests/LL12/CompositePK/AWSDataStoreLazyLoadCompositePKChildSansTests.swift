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
        let savedParent = try await createAndWaitForSync(parent)
        let child = initChildSansBelongsTo(with: savedParent)
        try await createAndWaitForSync(child)
    }
    
    func testUpdateChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await createAndWaitForSync(parent)
        let child = initChildSansBelongsTo(with: parent)
        var savedChild = try await createAndWaitForSync(child)
        XCTAssertEqual(savedChild.compositePKParentChildrenSansBelongsToCustomId, savedParent.customId)
        XCTAssertEqual(savedChild.compositePKParentChildrenSansBelongsToContent, savedParent.content)
        
        // update the child to a new parent
        let newParent = initParent()
        let savedNewParent = try await createAndWaitForSync(newParent)
        savedChild.compositePKParentChildrenSansBelongsToCustomId = savedNewParent.customId
        savedChild.compositePKParentChildrenSansBelongsToContent = savedNewParent.content
        let updatedChild = try await updateAndWaitForSync(savedChild)
        XCTAssertEqual(updatedChild.compositePKParentChildrenSansBelongsToCustomId, savedNewParent.customId)
        XCTAssertEqual(updatedChild.compositePKParentChildrenSansBelongsToContent, savedNewParent.content)
    }
    
    func testDeleteChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await createAndWaitForSync(parent)
        let child = initChildSansBelongsTo(with: parent)
        let savedChild = try await createAndWaitForSync(child)
        
        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
        
        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
    }
    
    func testGetChildSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        let savedParent = try await createAndWaitForSync(parent)
        let child = initChildSansBelongsTo(with: parent)
        let savedChild = try await createAndWaitForSync(child)
        
        // query parent and load the children
        let queriedParent = try await query(for: savedParent)
        assertList(queriedParent.childrenSansBelongsTo!, state: .isNotLoaded(associatedIds: [queriedParent.customId,
                                                                                             queriedParent.content],
                                                                             associatedFields: [
                                                                                "compositePKParentChildrenSansBelongsToCustomId",
                                                                                "compositePKParentChildrenSansBelongsToContent"]))
        try await queriedParent.childrenSansBelongsTo?.fetch()
        assertList(queriedParent.childrenSansBelongsTo!, state: .isLoaded(count: 1))
        
        // query children and verify the parent - ChildSansBelongsTo
        let queriedChildSansBelongsTo = try await query(for: savedChild)
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToCustomId, savedParent.customId)
        XCTAssertEqual(queriedChildSansBelongsTo.compositePKParentChildrenSansBelongsToContent, savedParent.content)
    }
}
