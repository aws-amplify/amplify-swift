//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class MutationEventQueryTests: BaseDataStoreTests {

    func testQueryPendingMutation_EmptyResult() {
        let querySuccess = expectation(description: "query mutation events success")
        let modelIds = [UUID().uuidString, UUID().uuidString]

        MutationEvent.pendingMutationEvents(for: modelIds, storageAdapter: storageAdapter) { result in
            switch result {
            case .success(let mutationEvents):
                XCTAssertTrue(mutationEvents.isEmpty)
                querySuccess.fulfill()
            case .failure(let error): XCTFail("\(error)")
            }
        }

        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEvent() {
        let mutationEvent = MutationEvent(id: UUID().uuidString,
                                          modelId: UUID().uuidString,
                                          modelName: Post.modelName,
                                          json: "",
                                          mutationType: .create)

        let querySuccess = expectation(description: "query for pending mutation events")

        storageAdapter.save(mutationEvent) { result in
            switch result {
            case .success:
                MutationEvent.pendingMutationEvents(for: mutationEvent.modelId,
                                                    storageAdapter: self.storageAdapter) { result in
                    switch result {
                    case .success(let mutationEvents):
                        XCTAssertEqual(mutationEvents.count, 1)
                        XCTAssertEqual(mutationEvents.first?.id, mutationEvent.id)
                        querySuccess.fulfill()
                    case .failure(let error): XCTFail("\(error)")
                    }
                }
            case .failure(let error): XCTFail("\(error)")
            }
        }
        wait(for: [querySuccess], timeout: 1)
    }

    func testQueryPendingMutationEventsForModelIds() {
        let mutationEvent1 = MutationEvent(id: UUID().uuidString,
                                           modelId: UUID().uuidString,
                                           modelName: Post.modelName,
                                           json: "",
                                           mutationType: .create)
        let mutationEvent2 = MutationEvent(id: UUID().uuidString,
                                           modelId: UUID().uuidString,
                                           modelName: Post.modelName,
                                           json: "",
                                           mutationType: .create)

        let saveMutationEvent1 = expectation(description: "save mutationEvent1 success")
        storageAdapter.save(mutationEvent1) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            saveMutationEvent1.fulfill()
        }
        wait(for: [saveMutationEvent1], timeout: 1)

        let saveMutationEvent2 = expectation(description: "save mutationEvent1 success")
        storageAdapter.save(mutationEvent2) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            saveMutationEvent2.fulfill()
        }
        wait(for: [saveMutationEvent2], timeout: 1)

        let querySuccess = expectation(description: "query for metadata success")
        var modelIds = [mutationEvent1.modelId]
        modelIds.append(contentsOf: (1 ... 999).map { _ in UUID().uuidString })
        modelIds.append(mutationEvent2.modelId)
        MutationEvent.pendingMutationEvents(for: modelIds,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .success(let mutationEvents):
                XCTAssertEqual(mutationEvents.count, 2)
                querySuccess.fulfill()
            case .failure(let error): XCTFail("\(error)")
            }
        }

        wait(for: [querySuccess], timeout: 1)
    }

    /// - Given: A create mutationSync with a given version
    /// - When: Mutation event table contains update and delete mutation events added in order, having same model id
    /// - Then: Update mutation event should be updated with version of create mutationSync

    func testQueryAfterUpdatePendingMutationEventVersion() {
        let modelId = UUID().uuidString
        let post = AnyModel(Post(id: modelId, title: "title", content: "content", createdAt: .now()))
        let updateMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: "",
                                                        mutationType: .update,
                                                        version: 1)
        let deleteMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: "",
                                                        mutationType: .delete,
                                                        version: 1)
        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 2)

        let createMutationSync = MutationSync(model: post, syncMetadata: metadata)

        let updateMutationExpectation = expectation(description: "save updateMutationEvent success")
        storageAdapter.save(updateMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation.fulfill()
        }
        wait(for: [updateMutationExpectation], timeout: 1)

        let deleteMutationExpectation = expectation(description: "save deleteMutationEvent success")
        storageAdapter.save(deleteMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            deleteMutationExpectation.fulfill()
        }
        wait(for: [deleteMutationExpectation], timeout: 1)

        let queryAfterUpdatingVersionExpectation = expectation(description: "query success")
        let updatingVersionExpectation = expectation(description: "update version success")
        MutationEvent.updatePendingMutationEventVersion(for: post.id,
                                                        mutationSync: createMutationSync,
                                                        storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                // query for head of mutation event table for given model id and check for version
                updatingVersionExpectation.fulfill()
                MutationEvent.pendingMutationEvents(for: post.id,
                                                    storageAdapter: self.storageAdapter) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail("Error : \(error)")
                    case .success(let mutationEvents):
                        queryAfterUpdatingVersionExpectation.fulfill()
                        guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                            XCTFail("Failure while updating version")
                            return
                        }
                        XCTAssertEqual(updatedEvent.version, createMutationSync.syncMetadata.version)
                        XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                    }
                }
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation, updatingVersionExpectation], timeout: 1)
    }
}
