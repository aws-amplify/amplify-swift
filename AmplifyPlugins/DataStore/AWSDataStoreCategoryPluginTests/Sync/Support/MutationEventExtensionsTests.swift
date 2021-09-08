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

    /// - Given: A pending mutation events queue with event containing `nil` version, a sent mutation event model that matches
    ///         the received mutation sync model. The received mutation sync has version 1.
    /// - When: The sent model matches the received model and the first pending mutation event version is `nil`.
    /// - Then: The pending mutation event version should be updated to the received model version of 1.
    func testSentModelWithNilVersion_Reconciled() throws {
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
                XCTAssertEqual(head, updateMutationEvent)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
        MutationEvent.reconcilePendingMutationEventsVersion(sent: createMutationEvent,
                                                             received: createMutationSync,
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, createMutationSync.syncMetadata.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with two events(update and delete) containing `nil` version, a sent mutation event
    ///         model that matches the received mutation sync model. The received mutation sync has version 1.
    /// - When: The sent model matches the received model, the first pending mutation event(update) version is `nil` and
    ///         the second pending mutation event(delete) version is `nil`.
    /// - Then: The first pending mutation event(update) version should be updated to the received model version of 1 and the second
    ///         pending mutation event version(delete) should not be updated.
    func testSentModelWithNilVersion_SecondPendingEventNotReconciled() throws {
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first, let last = mutationEvents.last else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head, updateMutationEvent)
                XCTAssertEqual(last, deleteMutationEvent)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
        MutationEvent.reconcilePendingMutationEventsVersion(sent: createMutationEvent,
                                                             received: createMutationSync,
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first, let last = mutationEvents.last else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, createMutationSync.syncMetadata.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                XCTAssertEqual(last, deleteMutationEvent)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with event containing version 2, a sent mutation event model that matches the
    ///         received mutation sync model having version 2. The received mutation sync has version 1.
    /// - When: The sent model matches the received model and the first pending mutation event version is 2.
    /// - Then: The first pending mutation event version should NOT be updated.
    func testSentModelVersionNewerThanResponseVersion_PendingEventNotReconciled() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let requestMutationEvent = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .create,
                                                version: 2,
                                                inProcess: true)

        let pendingMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 2)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 1)

        let responseMutationSync = MutationSync(model: AnyModel(post1), syncMetadata: metadata)

        let requestMutationEventExpectation = expectation(description: "save requestMutationEvent success")
        storageAdapter.save(requestMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            requestMutationEventExpectation.fulfill()
        }

        let pendingMutationEventExpectation = expectation(description: "save pendingMutationEvent success")
        storageAdapter.save(pendingMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            pendingMutationEventExpectation.fulfill()
        }

        wait(for: [requestMutationEventExpectation, pendingMutationEventExpectation], timeout: 1)

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
                XCTAssertEqual(head, pendingMutationEvent)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(sent: requestMutationEvent,
                                                             received: responseMutationSync,
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNotEqual(head.version, responseMutationSync.syncMetadata.version)
                XCTAssertEqual(head, pendingMutationEvent)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with event containing version 1, a sent mutation event model that doesn't match
    ///         the received mutation sync model having version 1. The received mutation sync has version 2.
    /// - When: The sent model doesn't match the received model and the first pending mutation event version is 1.
    /// - Then: The first pending mutation event version should NOT be updated.
    func testSentModelNotEqualToResponseModel_PendingEventNotReconciled() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let post3 = Post(id: modelId, title: "title3", content: "content3", createdAt: .now())
        let requestMutationEvent = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .update,
                                                version: 1,
                                                inProcess: true)

        let pendingMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 1)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 2)

        let responseMutationSync = MutationSync(model: AnyModel(post3), syncMetadata: metadata)

        let requestMutationEventExpectation = expectation(description: "save requestMutationEvent success")
        storageAdapter.save(requestMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            requestMutationEventExpectation.fulfill()
        }

        let pendingMutationEventExpectation = expectation(description: "save pendingMutationEvent success")
        storageAdapter.save(pendingMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            pendingMutationEventExpectation.fulfill()
        }

        wait(for: [requestMutationEventExpectation, pendingMutationEventExpectation], timeout: 1)

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
                XCTAssertEqual(head, pendingMutationEvent)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(sent: requestMutationEvent,
                                                             received: responseMutationSync,
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertNotEqual(head.version, responseMutationSync.syncMetadata.version)
                XCTAssertEqual(head, pendingMutationEvent)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with event containing version 1, a sent mutation event model that matches
    ///         the received mutation sync model having version 1. The received mutation sync has version 2.
    /// - When: The sent model matches the received model and the first pending mutation event version is 1.
    /// - Then: The first pending mutation event version should be updated to received mutation sync version i.e. 2.
    func testPendingVersionReconciledSuccess() throws {
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let requestMutationEvent = MutationEvent(id: UUID().uuidString,
                                                modelId: modelId,
                                                modelName: Post.modelName,
                                                json: try post1.toJSON(),
                                                mutationType: .update,
                                                version: 1,
                                                inProcess: true)

        let pendingMutationEvent = MutationEvent(id: UUID().uuidString,
                                                        modelId: modelId,
                                                        modelName: Post.modelName,
                                                        json: try post2.toJSON(),
                                                        mutationType: .update,
                                                        version: 1)

        let metadata = MutationSyncMetadata(id: modelId,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: 2)

        let responseMutationSync = MutationSync(model: AnyModel(post1), syncMetadata: metadata)

        let requestMutationEventExpectation = expectation(description: "save requestMutationEvent success")
        storageAdapter.save(requestMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            requestMutationEventExpectation.fulfill()
        }

        let pendingMutationEventExpectation = expectation(description: "save pendingMutationEvent success")
        storageAdapter.save(pendingMutationEvent) { result in
            guard case .success = result else {
                XCTFail("Failed to save metadata")
                return
            }
            pendingMutationEventExpectation.fulfill()
        }

        wait(for: [requestMutationEventExpectation, pendingMutationEventExpectation], timeout: 1)

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
                XCTAssertEqual(head, pendingMutationEvent)
                queryBeforeUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryBeforeUpdatingVersionExpectation], timeout: 1)

        MutationEvent.reconcilePendingMutationEventsVersion(sent: requestMutationEvent,
                                                             received: responseMutationSync,
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
                guard !mutationEvents.isEmpty, let head = mutationEvents.first else {
                    XCTFail("Failure while updating version")
                    return
                }
                XCTAssertEqual(head.version, responseMutationSync.syncMetadata.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }
}
