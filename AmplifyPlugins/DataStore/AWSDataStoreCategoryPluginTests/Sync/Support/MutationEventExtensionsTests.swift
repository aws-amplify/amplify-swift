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

// swiftlint:disable cyclomatic_complexity
// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable line_length
class MutationEventExtensionsTest: BaseDataStoreTests {

    /// - Given: A create mutationSync with version 1
    /// - When: Mutation event table contains a create mutation event with `nil` version, inProcess` as true
    ///        and an update mutation event with `nil` version, having the same model
    /// - Then: After reconciliation of versions, Update mutation event should be updated with version of
    ///   create mutationSync
    func testQueryAfterReconcilePendingMutationEventVersionGivenSingleMutationEvent() throws {
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

    /// - Given: A create mutationSync with version 1
    /// - When: Mutation event table contains a create mutation event with `nil` version, inProcess` as true;
    ///        and update and delete mutation events added in order with `nil` version, having the same model
    /// - Then: After reconciliation of versions, Update mutation event should be updated with version of create mutationSync
    func testQueryAfterReconcilePendingMutationEventVersionGivenMultipleMutationEvents() throws {
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

    /// - Given: A update mutationSync with version 1
    /// - When: Mutation event table contains a update mutation event with version 2, `inProcess` as true
    ///        and an update mutation event with version 2. The pending mutation event with `inProcess` set to true has the
    ///        same model contained in update mutationSync
    /// - Then: After reconciliation of versions, Update mutation event should NOT be updated with version of create mutationSync
    func testQueryAfterReconcilePendingMutationEventVersionGivenOldVersionInResponse() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let updateMutationEvent1 = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .create,
                                                version: 2,
                                                inProcess: true)

        let updateMutationEvent2 = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 2)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)

        let updateMutationSync = MutationSync(model: AnyModel(post1), syncMetadata: metadata)

        let updateMutationExpectation1 = expectation(description: "save updateMutationEvent1 success")
        storageAdapter.save(updateMutationEvent1) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation1.fulfill()
        }

        let updateMutationExpectation2 = expectation(description: "save updateMutationEvent2 success")
        storageAdapter.save(updateMutationEvent2) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation2.fulfill()
        }

        wait(for: [updateMutationExpectation1, updateMutationExpectation2], timeout: 1)

        let queryBeforeUpdatingVersionExpectation = expectation(description: "update mutation should have version 2")
        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 2")
        let updatingVersionExpectation = expectation(description: "don't update latest mutation event with response version")

        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, 2)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(mutationEvent: updateMutationEvent1,
                                                             mutationSync: updateMutationSync,
                                                             storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                updatingVersionExpectation.fulfill()
            }
        }
        wait(for: [updatingVersionExpectation], timeout: 1)

        // query for head of mutation event table for given model id and check if it has the correct version
        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNotEqual(updatedEvent.version, updateMutationSync.syncMetadata.version)
                XCTAssertEqual(updatedEvent.version, 2)
                XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A update mutationSync with version 2
    /// - When: Mutation event table contains a update mutation event with version 1, `inProcess` as true
    ///        and an update mutation event with version 1. Both pending mutation events have different model than contained
    ///        in update mutationSync
    /// - Then: After reconciliation of versions, Update mutation event with `inProcess` set to false
    ///        should NOT be updated with version of update mutationSync
    func testQueryAfterReconcilePendingMutationEventVersionGivenDifferentModelInResponse() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let post3 = Post(id: modelId, title: "title3", content: "content3", createdAt: .now())
        let updateMutationEvent1 = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .update,
                                                version: 1,
                                                inProcess: true)

        let updateMutationEvent2 = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 1)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 2)

        let updateMutationSync = MutationSync(model: AnyModel(post3), syncMetadata: metadata)

        let updateMutationExpectation1 = expectation(description: "save updateMutationEvent1 success")
        storageAdapter.save(updateMutationEvent1) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation1.fulfill()
        }

        let updateMutationExpectation2 = expectation(description: "save updateMutationEvent2 success")
        storageAdapter.save(updateMutationEvent2) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation2.fulfill()
        }

        wait(for: [updateMutationExpectation1, updateMutationExpectation2], timeout: 1)

        let queryBeforeUpdatingVersionExpectation = expectation(description: "update mutation should have version 1")
        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 1")
        let updatingVersionExpectation = expectation(description: "don't update latest mutation event with response version")

        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, 1)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(mutationEvent: updateMutationEvent1,
                                                             mutationSync: updateMutationSync,
                                                             storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                updatingVersionExpectation.fulfill()
            }
        }
        wait(for: [updatingVersionExpectation], timeout: 1)

        // query for head of mutation event table for given model id and check if it has the correct version
        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNotEqual(updatedEvent.version, updateMutationSync.syncMetadata.version)
                XCTAssertEqual(updatedEvent.version, 1)
                XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A update mutationSync with version 2
    /// - When: Mutation event table contains a update mutation event with version 1, `inProcess` as true
    ///        and an update mutation event with version 1. The pending mutation event with `inProcess` set to true has the
    ///        same model contained in update mutationSync
    /// - Then: After reconciliation of versions, Update mutation event with `inProcess` set to false
    ///        should be updated with version of update mutationSync
    func testQueryAfterReconcilePendingMutationEventVersionGivenSameModelInResponse() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let updateMutationEvent1 = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .update,
                                                version: 1,
                                                inProcess: true)

        let updateMutationEvent2 = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 1)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 2)

        let updateMutationSync = MutationSync(model: AnyModel(post1), syncMetadata: metadata)

        let updateMutationExpectation1 = expectation(description: "save updateMutationEvent1 success")
        storageAdapter.save(updateMutationEvent1) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation1.fulfill()
        }

        let updateMutationExpectation2 = expectation(description: "save updateMutationEvent2 success")
        storageAdapter.save(updateMutationEvent2) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            updateMutationExpectation2.fulfill()
        }

        wait(for: [updateMutationExpectation1, updateMutationExpectation2], timeout: 1)

        let queryBeforeUpdatingVersionExpectation = expectation(description: "update mutation should have version 1")
        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 2")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, 1)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(mutationEvent: updateMutationEvent1,
                                                             mutationSync: updateMutationSync,
                                                             storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success:
                updatingVersionExpectation.fulfill()
            }
        }
        wait(for: [updatingVersionExpectation], timeout: 1)

        // query for head of mutation event table for given model id and check if it has the correct version
        MutationEvent.pendingMutationEvents(for: post1.id,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let mutationEvents):
                guard !mutationEvents.isEmpty, let updatedEvent = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(updatedEvent.version, updateMutationSync.syncMetadata.version)
                XCTAssertEqual(updatedEvent.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }
}
