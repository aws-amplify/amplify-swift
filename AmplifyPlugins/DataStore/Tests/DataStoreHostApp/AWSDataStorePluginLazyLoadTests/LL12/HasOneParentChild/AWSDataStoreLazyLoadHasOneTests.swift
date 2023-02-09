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
        try await saveAndWaitForSync(parent)
    }
    
    func testSaveHasOneChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        try await saveAndWaitForSync(child)
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
        
        // The child can be lazy loaded.
        assertLazyReference(queriedParent._child, state: .notLoaded(identifiers: [.init(name: "id", value: child.id)]))
        let queriedParentChild = try await queriedParent.child!
        XCTAssertEqual(queriedParentChild.id, child.id)
        
        // The child model id can be found on the explicit field.
        let childId = queriedParent.hasOneParentChildId
        XCTAssertEqual(childId, child.id)
        
        // Delete
        try await deleteAndWaitForSync(parent)
        try await assertModelDoesNotExist(parent)
        try await assertModelExists(child)
        try await deleteAndWaitForSync(child)
        try await assertModelDoesNotExist(child)
    }

    func testUpdateParentWithNewChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await saveAndWaitForSync(parent)

        var queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        // The child can be lazy loaded.
        assertLazyReference(queriedParent._child,
                            state: .notLoaded(identifiers: [
                                .init(name: HasOneChild.keys.id.stringValue, value: child.id)
                            ]))

        let newChild = HasOneChild()
        let savedNewChild = try await saveAndWaitForSync(newChild)

        // Update parent to new child
        queriedParent.setChild(savedNewChild)
        queriedParent.hasOneParentChildId = savedNewChild.id
        try await updateAndWaitForSync(queriedParent)

        let queriedParentWithNewChild = try await query(for: parent)
        // The child can be lazy loaded.
        assertLazyReference(queriedParentWithNewChild._child, state: .notLoaded(identifiers: [
            .init(name: HasOneChild.keys.id.stringValue, value: savedNewChild.id)
        ]))
        XCTAssertEqual(queriedParentWithNewChild.hasOneParentChildId, savedNewChild.id)
    }

    func testObserveHasOneChild() async throws {
        await setup(withModels: HasOneModels())
        try await startAndWaitForReady()
        let child = HasOneChild()
        let mutationEventReceived = asyncExpectation(description: "Received mutation event")
        let mutationEvents = Amplify.DataStore.observe(HasOneChild.self)

        Task {
            for try await mutationEvent in mutationEvents {
                if let version = mutationEvent.version,
                   version == 1,
                   let receivedChild = try? mutationEvent.decodeModel(as: HasOneChild.self),
                   receivedChild.identifier == child.identifier
                {
                    await mutationEventReceived.fulfill()
                }
            }
        }

        let createRequest = GraphQLRequest<MutationSyncResult>.createMutation(of: child, modelSchema: HasOneChild.schema)
        do {
            _ = try await Amplify.API.mutate(request: createRequest)
        } catch {
            XCTFail("Failed to send mutation request \(error)")
        }

        await waitForExpectations([mutationEventReceived], timeout: 60)
        mutationEvents.cancel()
    }

    func testDeleteHasOneChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        try await assertModelExists(savedChild)

        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
    }

    func testDeleteHasOneParent() async throws {
        await setup(withModels: HasOneModels())
        let parent = HasOneParent()
        let savedParent = try await saveAndWaitForSync(parent)
        try await assertModelExists(savedParent)

        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
    }

    func testDeleteHasOneParentWithChild() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await saveAndWaitForSync(parent)

        let queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
    }

    func testDeleteHasOneChildWithParent() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await saveAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await saveAndWaitForSync(parent)

        let queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
        try await assertModelExists(savedParent)

        let childIdInParent = try await query(for: savedParent).child?.id
        XCTAssertEqual(childIdInParent, nil)
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
