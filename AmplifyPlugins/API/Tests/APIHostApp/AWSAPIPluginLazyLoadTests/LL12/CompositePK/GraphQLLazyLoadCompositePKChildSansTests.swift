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
}
