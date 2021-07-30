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

class MutationEventExtensionsTest: BaseDataStoreTests {
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
                                                        version: nil)
        let deleteMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: "",
                                                        mutationType: .delete,
                                                        version: nil)
        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)

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
        MutationEvent.updatePendingMutationEventVersionIfNil(for: post.id,
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
