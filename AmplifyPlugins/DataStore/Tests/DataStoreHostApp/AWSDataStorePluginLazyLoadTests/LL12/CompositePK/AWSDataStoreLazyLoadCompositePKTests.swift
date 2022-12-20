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

class AWSDataStoreLazyLoadCompositePKTests: AWSDataStoreLazyLoadBaseTest {
    func testStart() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        try await startAndWaitForReady()
    }
    
    func testSaveCompositePKParent() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
    }
    
    func testSaveCompositePKChild() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await saveAndWaitForSync(compositePKChild)
    }
    
    func testSaveImplicitChild() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await saveAndWaitForSync(implicitChild)
    }
    
    func testSaveExplicitChild() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await saveAndWaitForSync(childSansBelongsTo)
    }
    
    func testSaveStrangeImplicitChild() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeExplicitChild = try await saveAndWaitForSync(strangeExplicitChild)
    }
    
    func testSaveSansBelongsTo() async throws {
        await setup(withModels: CompositePKModels(), clearOnTearDown: false)
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        
        let childSansBelongsTo = ChildSansBelongsTo(
            childId: UUID().uuidString,
            content: "content",
            compositePKParentChildrenSansBelongsToCustomId: savedParent.customId,
            compositePKParentChildrenSansBelongsToContent: savedParent.content)
        let savedChildSansBelongsTo = try await saveAndWaitForSync(childSansBelongsTo)
    }
}

extension AWSDataStoreLazyLoadCompositePKTests {
    
    struct CompositePKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: CompositePKParent.self)
            ModelRegistry.register(modelType: CompositePKChild.self)
            ModelRegistry.register(modelType: ImplicitChild.self)
            ModelRegistry.register(modelType: StrangeExplicitChild.self)
            ModelRegistry.register(modelType: ChildSansBelongsTo.self)
        }
    }
}
