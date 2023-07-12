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

    /*
     - Given: DataStore is cleared
     - When: Configured with `HashOneModels`
     - Then: Successfully start the sync engine
     */
    func testStart_withHasOneModels_success() async throws {
        await setup(withModels: HasOneModels())
        try await startAndWaitForReady()
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance without `HasOneChild` association
     - Then: Successfully saved and synced to remote
     */
    func testSaveHasOneParent_withoutChild_success() async throws {
        await setup(withModels: HasOneModels())
        let parent = HasOneParent()
        try await createAndWaitForSync(parent)
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneChild` instance
     - Then: Successfully saved and synced to remote
     */
    func testSaveHasOneChild_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        try await createAndWaitForSync(child)
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance with `HasOneChild` association
     - Then: Successfully saved and synced to remote
     */
    func testSaveHasOneParent_withChild_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        try await createAndWaitForSync(child)
        // populating `hasOneParentChildId` is required to sync successfully
        let parent = HasOneParent(child: child, hasOneParentChildId: child.id)
        try await createAndWaitForSync(parent)
        
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

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance with `HasOneChild` association
        - Update `HasOneParent` instance with a new `HasOneChild` association
     - Then: Successfully updated and synced to remote
     */
    func testUpdateHasOneParent_withNewChild_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await createAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await createAndWaitForSync(parent)

        var queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        // The child can be lazy loaded.
        assertLazyReference(queriedParent._child,
                            state: .notLoaded(identifiers: [
                                .init(name: HasOneChild.keys.id.stringValue, value: child.id)
                            ]))

        let newChild = HasOneChild()
        let savedNewChild = try await createAndWaitForSync(newChild)

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

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance with `HasOneChild` association
        - Update `HasOneParent` instance with a new `HasOneChild` association
     - Then: Successfully updated and synced to remote
     */
    func testCreateHasOneChild_withObserve_success() async throws {
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

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneChild` instance
        - Delete the `HasOneChild` instance
     - Then: Successfully deleted and synced to remote
     */
    func testDeleteHasOneChild_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await createAndWaitForSync(child)
        try await assertModelExists(savedChild)

        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance without `HasOneChild` association
        - Delete the `HasOneParent` instance
     - Then: Successfully deleted and synced to remote
     */
    func testDeleteHasOneParent_withoutChild_success() async throws {
        await setup(withModels: HasOneModels())
        let parent = HasOneParent()
        let savedParent = try await createAndWaitForSync(parent)
        try await assertModelExists(savedParent)

        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneParent` instance with `HasOneChild` association
        - Delete the `HasOneParent` instance
     - Then: Successfully deleted and synced to remote
     */
    func testDeleteHasOneParent_withChild_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await createAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await createAndWaitForSync(parent)

        let queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        try await deleteAndWaitForSync(savedParent)
        try await assertModelDoesNotExist(savedParent)
        try await assertModelExists(savedChild)
    }

    /*
     - Given: DataStore is cleared
     - When:
        - Configured with `HashOneModels`
        - Create a new `HasOneChild` instance and associated to a `HasOneParent` instance
        - Delete the `HasOneChild` instance
     - Then: Successfully deleted and synced to remote
     */
    func testDeleteHasOneChild_withParent_success() async throws {
        await setup(withModels: HasOneModels())
        let child = HasOneChild()
        let savedChild = try await createAndWaitForSync(child)
        let parent = HasOneParent(child: savedChild, hasOneParentChildId: savedChild.id)
        let savedParent = try await createAndWaitForSync(parent)

        let queriedParent = try await query(for: savedParent)
        XCTAssertEqual(queriedParent.hasOneParentChildId, savedChild.id)

        try await deleteAndWaitForSync(savedChild)
        try await assertModelDoesNotExist(savedChild)
        try await assertModelExists(savedParent)

        let associatedChild = try await query(for: savedParent).child
        XCTAssertTrue(associatedChild == nil)
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
