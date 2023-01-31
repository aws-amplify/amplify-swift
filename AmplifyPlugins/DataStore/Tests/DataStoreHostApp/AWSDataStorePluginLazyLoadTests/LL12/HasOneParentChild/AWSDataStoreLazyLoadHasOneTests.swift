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
        await setup(withModels: HasOneModels())
        try await startAndWaitForReady()
    }
    
    func testSaveHasOneParent() async throws {
        await setup(withModels: HasOneModels())
        let parent = HasOneParent()
        let savedParent = try await saveAndWaitForSync(parent)
    }
    
    func testSaveHasOneChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
    }
    
    func testSaveParentWithChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: child)
        let savedParent = try await saveAndWaitForSync(parent)
    }

    func testUpdateParentWithNewChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await saveAndWaitForSync(parent)

        var queriedParent = try await query(for: parent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        let newChild = HasOneChild()
        let savedNewChild = try await saveAndWaitForSync(newChild)
        queriedParent.setChild(savedNewChild)
        queriedParent.hasOneParentChildId = savedNewChild.id
        try await updateAndWaitForSync(queriedParent)
        print("New Child \(savedNewChild)")
        print("Parent: \(savedParent)")

        let queriedParentV2 = try await query(for: parent)
        print("ParentV2: \(queriedParentV2)")
        XCTAssertEqual(queriedParentV2.hasOneParentChildId, savedNewChild.id)

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
