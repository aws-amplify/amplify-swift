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
        try await saveAndWaitForSync(child)
        // populating `hasOneParentChildId` is required to sync successfully
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        try await saveAndWaitForSync(parent)
        
        // Query from API
        let response = try await Amplify.API.query(request: .get(HasOneParent.self, byId: parent.id))
        switch response {
        case .success(let queriedParent):
            guard let queriedParent = queriedParent else {
                XCTFail("Unexpected, query should return model")
                return
            }
            guard let queriedParentChild = try await queriedParent.child else {
                XCTFail("Failed to lazy load child")
                return
            }
            XCTAssertEqual(queriedParentChild.id, child.id)
        case .failure(let error):
            XCTFail("Error querying for parent directly from AppSync \(error)")
        }
        
        // Query from DataStore
        let queriedParent = try await query(for: parent)
        
        // The lazy model isn't populated here, hence the child lazy reference is nil
        assertLazyReference(queriedParent._child, state: .notLoaded(identifiers: nil))
        
        // The child model id can be found on the explicit field.
        let childId = queriedParent.hasOneParentChildId
        XCTAssertEqual(childId, child.id)
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
