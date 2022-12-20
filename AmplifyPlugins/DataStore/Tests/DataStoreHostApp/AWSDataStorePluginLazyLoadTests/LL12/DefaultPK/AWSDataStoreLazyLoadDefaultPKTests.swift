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

class AWSDataStoreLazyLoadDefaultPKTests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: DefaultPKModels(), clearOnTearDown: false)
        try await startAndWaitForReady()
    }
    
    func testSaveDefaultPKParent() async throws {
        await setup(withModels: DefaultPKModels(), clearOnTearDown: false)
        let parent = DefaultPKParent()
        let savedParent = try await saveAndWaitForSync(parent)
    }
    
    func testSaveDefaultPKChild() async throws {
        await setup(withModels: DefaultPKModels(), clearOnTearDown: false)
        let parent = DefaultPKParent()
        let savedParent = try await saveAndWaitForSync(parent)
        let child = DefaultPKChild(parent: parent)
        let savedChild = try await saveAndWaitForSync(child)
    }
}

extension AWSDataStoreLazyLoadDefaultPKTests {
    
    struct DefaultPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: DefaultPKChild.self)
            ModelRegistry.register(modelType: DefaultPKParent.self)
        }
    }
}
