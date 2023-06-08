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
        await setup(withModels: CompositePKModels())
        try await startAndWaitForReady()
    }
    
    func testSaveCompositePKParent() async throws {
        await setup(withModels: CompositePKModels())
        let parent = initParent()
        try await saveAndWaitForSync(parent)
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
    
    func initParent() -> CompositePKParent {
        CompositePKParent(customId: UUID().uuidString,
                          content: UUID().uuidString)
    }
}
