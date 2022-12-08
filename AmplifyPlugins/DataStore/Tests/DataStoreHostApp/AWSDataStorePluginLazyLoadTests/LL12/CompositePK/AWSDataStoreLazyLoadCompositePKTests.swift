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
        await setup(withModels: CompositePKModels(), eagerLoad: false, clearOnTearDown: false)
        try await startAndWaitForReady()
    }
    
    func testSave() async throws {
        await setup(withModels: CompositePKModels(), eagerLoad: false, clearOnTearDown: false)
        
        let compositePKParent = CompositePKParent(customId: UUID().uuidString,
                                                  content: "content")
        let savedParent = try await saveAndWaitForSync(compositePKParent)
        let compositePKChild = CompositePKChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedCompositePKChild = try await saveAndWaitForSync(compositePKChild)
        let implicitChild = ImplicitChild(childId: UUID().uuidString, content: "content", parent: savedParent)
        let savedImplicitChild = try await saveAndWaitForSync(implicitChild)
        let strangeExplicitChild = StrangeExplicitChild(strangeId: UUID().uuidString, content: "content", parent: savedParent)
        let savedStrangeImplicitChild = try await saveAndWaitForSync(strangeExplicitChild)
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
