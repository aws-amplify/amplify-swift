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

/// swiftlint:disable cyclomatic_complexity
class MutationEventExtensionsTest: BaseDataStoreTests {

    /// - Given: A create mutationSync with a given version
    /// - When: Mutation event table contains an update mutation event with `nil` version, having same model id
    /// - Then: Update mutation event should be updated with version of create mutationSync
    func testQueryAfterUpdatePendingMutationEventVersionGivenSingleMutationEvent() throws {
        let modelId = UUID().uuidString
        let post = Post(id: modelId, title: "title", content: "content", createdAt: .now())
        let createMutationEvent = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post.toJSON(),
                                                mutationType: .create,
                                                version: nil,
                                                inProcess: true)

        let updateMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post.toJSON(),
                                                        mutationType: .update,
                                                        version: nil)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)

        let createMutationSync = MutationSync(model: AnyModel(post), syncMetadata: metadata)

        let createMutationExpectation = expectation(description: "save createMutationEvent success")
        storageAdapter.save(createMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            createMutationExpectation.fulfill()
        }

        let updateMutationExpectation = expectation(description: "save updateMutationEvent success")
        storageAdapter.save(updateMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation.fulfill()
        }

        wait(for: [createMutationExpectation, updateMutationExpectation], timeout: 1)

        let queryBeforeUpdatingVersionExpectation = expectation(description: "update mutation should have nil version")
        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should be latest version")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

        // query for the head of mutation event table for given model id and check if it has `nil` version
        MutationEvent.pendingMutationEvents(for: post.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNil(head.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
        MutationEvent.reconcilePendingMutationEventsVersion(mutationEvent: createMutationEvent,
                                                             mutationSync: createMutationSync,
                                                             storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                updatingVersionExpectation.fulfill()
            }
        }
        wait(for: [updatingVersionExpectation], timeout: 1)

        // query for head of mutation event table for given model id and check if it has the updated version
        MutationEvent.pendingMutationEvents(for: post.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(updatedEvent.version, createMutationSync.syncMetadata.version)
                XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A create mutationSync with a given version
    /// - When: Mutation event table contains update and delete mutation events added in order with `nil` version,
    ///        having same model id
    /// - Then: Update mutation event should be updated with version of create mutationSync
    func testQueryAfterUpdatePendingMutationEventVersionGivenMultipleMutationEvents() throws{
        let modelId = UUID().uuidString
        let post = Post(id: modelId, title: "title", content: "content", createdAt: .now())
        let createMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post.toJSON(),
                                                        mutationType: .create,
                                                        version: nil,
                                                        inProcess: true)
        let updateMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post.toJSON(),
                                                        mutationType: .update,
                                                        version: nil)
        let deleteMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post.toJSON(),
                                                        mutationType: .delete,
                                                        version: nil)
        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)

        let createMutationSync = MutationSync(model: AnyModel(post), syncMetadata: metadata)

        let createMutationExpectation = expectation(description: "save createMutationEvent success")
        storageAdapter.save(createMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            createMutationExpectation.fulfill()
        }

        let updateMutationExpectation = expectation(description: "save updateMutationEvent success")
        storageAdapter.save(updateMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation.fulfill()
        }

        let deleteMutationExpectation = expectation(description: "save deleteMutationEvent success")
        storageAdapter.save(deleteMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            deleteMutationExpectation.fulfill()
        }
        wait(for: [createMutationExpectation, updateMutationExpectation, deleteMutationExpectation], timeout: 1)

        let queryBeforeUpdatingVersionExpectation = expectation(description: "update mutation should have nil version")
        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should be latest version")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

        // query for the head of mutation event table for given model id and check if it has `nil` version
        MutationEvent.pendingMutationEvents(for: post.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNil(head.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
        MutationEvent.reconcilePendingMutationEventsVersion(mutationEvent: createMutationEvent,
                                                             mutationSync: createMutationSync,
                                                             storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                updatingVersionExpectation.fulfill()
            }
        }
        wait(for: [updatingVersionExpectation], timeout: 1)

        // query for head of mutation event table for given model id and check if it has the updated version
        MutationEvent.pendingMutationEvents(for: post.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(updatedEvent.version, createMutationSync.syncMetadata.version)
                XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

}
