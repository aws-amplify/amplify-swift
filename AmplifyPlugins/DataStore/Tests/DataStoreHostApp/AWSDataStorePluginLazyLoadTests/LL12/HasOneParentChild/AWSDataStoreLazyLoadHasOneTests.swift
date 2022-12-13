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

class AWSDataStoreLazyLoadHasOneTests: AWSDataStoreLazyLoadBaseTest {
    
    func testStart() async throws {
        await setup(withModels: HasOneModels(), eagerLoad: false, clearOnTearDown: false)
        try await startAndWaitForReady()
    }
    
    func testSaveHasOneParent() async throws {
        await setup(withModels: HasOneModels(), eagerLoad: false, clearOnTearDown: false)
        let parent = HasOneParent()
        let savedParent = try await saveAndWaitForSync(parent)
    }
    
    func testSaveHasOneChild() async throws {
        await setup(withModels: HasOneModels(), eagerLoad: false, clearOnTearDown: false)
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
    }
    
    func testSaveParentWithChild() async throws {
        await setup(withModels: HasOneModels(), eagerLoad: false, clearOnTearDown: false)
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: child)
        let savedParent = try await saveAndWaitForSync(parent)
    }
}

extension AWSDataStoreLazyLoadHasOneTests {
    
    struct HasOneModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: HasOneChild.self)
            ModelRegistry.register(modelType: HasOneParent.self)
        }
    }
}
