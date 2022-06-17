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
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore

// TODO: This flaky test has been disabled, tracking issue: https://github.com/aws-amplify/amplify-ios/issues/1831
// swiftlint:disable type_body_length
class MutationEventExtensionsTest: BaseDataStoreTests {

    /// - Given: A pending mutation events queue with event containing `nil` version, a sent mutation
    ///         event model that matches the received mutation sync model. The received mutation sync has version 1.
    /// - When: The sent model matches the received model and the first pending mutation event version is `nil`.
    /// - Then: The pending mutation event version should be updated to the received model version of 1.
    func testSentModelWithNilVersion_Reconciled() throws {
        throw XCTSkip("TODO: fix this test")
        let modelId = UUID().uuidString
        let post = Post(id: modelId, title: "title", content: "content", createdAt: .now())
        let requestMutationEvent = try createMutationEvent(model: post,
                                                           mutationType: .create,
                                                           createdAt: .now(),
                                                           version: nil,
                                                           inProcess: true)
        let pendingMutationEvent = try createMutationEvent(model: post,
                                                           mutationType: .update,
                                                           createdAt: .now().add(value: 1, to: .second),
                                                           version: nil)
        let responseMutationSync = createMutationSync(model: post, version: 1)

        setUpPendingMutationQueue(modelId, [requestMutationEvent, pendingMutationEvent], pendingMutationEvent)

        let reconciledEvent = MutationEvent.reconcile(pendingMutationEvent: pendingMutationEvent,
                                                      with: requestMutationEvent,
                                                      responseMutationSync: responseMutationSync)
        XCTAssertNotNil(reconciledEvent)
        XCTAssertEqual(reconciledEvent?.version, responseMutationSync.syncMetadata.version)

        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should be latest version")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
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
                XCTAssertEqual(head.version, responseMutationSync.syncMetadata.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with two events(update and delete) containing `nil` version,
    ///         a sent mutation event model that matches the received mutation sync model. The received mutation
    ///         sync has version 1.
    /// - When: The sent model matches the received model, the first pending mutation event(update) version is `nil` and
    ///         the second pending mutation event(delete) version is `nil`.
    /// - Then: The first pending mutation event(update) version should be updated to the received model version of 1
    ///         and the second pending mutation event version(delete) should not be updated.
    func testSentModelWithNilVersion_SecondPendingEventNotReconciled() throws {
        throw XCTSkip("TODO: fix this test")
        let modelId = UUID().uuidString
        let post = Post(id: modelId, title: "title", content: "content", createdAt: .now())
        let requestMutationEvent = try createMutationEvent(model: post,
                                                           mutationType: .create,
                                                           createdAt: .now(),
                                                           version: nil,
                                                           inProcess: true)
        let pendingUpdateMutationEvent = try createMutationEvent(model: post,
                                                                 mutationType: .update,
                                                                 createdAt: .now().add(value: 1, to: .second),
                                                                 version: nil)
        let pendingDeleteMutationEvent = try createMutationEvent(model: post,
                                                                 mutationType: .delete,
                                                                 createdAt: .now().add(value: 2, to: .second),
                                                                 version: nil)
        let responseMutationSync = createMutationSync(model: post, version: 1)

        setUpPendingMutationQueue(modelId,
                                  [requestMutationEvent, pendingUpdateMutationEvent, pendingDeleteMutationEvent],
                                  pendingUpdateMutationEvent)

        let reconciledEvent = MutationEvent.reconcile(pendingMutationEvent: pendingUpdateMutationEvent,
                                                      with: requestMutationEvent,
                                                      responseMutationSync: responseMutationSync)
        XCTAssertNotNil(reconciledEvent)
        XCTAssertEqual(reconciledEvent?.version, responseMutationSync.syncMetadata.version)

        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should be latest version")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

        // update the version of head of mutation event table for given model id to the version of `mutationSync`
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
                XCTAssertEqual(head.version, responseMutationSync.syncMetadata.version)
                XCTAssertEqual(head.mutationType, MutationEvent.MutationType.update.rawValue)
                XCTAssertEqual(last, pendingDeleteMutationEvent)
                queryAfterUpdatingVersionExpectation.fulfill()
            }
        }
        wait(for: [queryAfterUpdatingVersionExpectation], timeout: 1)
    }

    /// - Given: A pending mutation events queue with event containing version 2, a sent mutation event model
    ///         that matches the received mutation sync model having version 2. The received mutation sync has
    ///         version 1.
    /// - When: The sent model matches the received model and the first pending mutation event version is 2.
    /// - Then: The first pending mutation event version should NOT be updated.
    func testSentModelVersionNewerThanResponseVersion_PendingEventNotReconciled() throws {
        throw XCTSkip("TODO: fix this test")
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let requestMutationEvent = try createMutationEvent(model: post1,
                                                           mutationType: .create,
                                                           createdAt: .now(),
                                                           version: 2,
                                                           inProcess: true)
        let pendingMutationEvent = try createMutationEvent(model: post2,
                                                           mutationType: .update,
                                                           createdAt: .now().add(value: 1, to: .second),
                                                           version: 2)
        let responseMutationSync = createMutationSync(model: post1, version: 1)

        setUpPendingMutationQueue(modelId, [requestMutationEvent, pendingMutationEvent], pendingMutationEvent)

        let reconciledEvent = MutationEvent.reconcile(pendingMutationEvent: pendingMutationEvent,
                                                      with: requestMutationEvent,
                                                      responseMutationSync: responseMutationSync)
        XCTAssertNil(reconciledEvent)

        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 2")
        let updatingVersionExpectation =
            expectation(description: "don't update latest mutation event with response version")

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

    /// - Given: A pending mutation events queue with event containing version 1, a sent mutation event model
    ///         that doesn't match the received mutation sync model having version 1. The received mutation
    ///         sync has version 2.
    /// - When: The sent model doesn't match the received model and the first pending mutation event version is 1.
    /// - Then: The first pending mutation event version should NOT be updated.
    func testSentModelNotEqualToResponseModel_PendingEventNotReconciled() throws {
        throw XCTSkip("TODO: fix this test")
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let post3 = Post(id: modelId, title: "title3", content: "content3", createdAt: .now())
        let requestMutationEvent = try createMutationEvent(model: post1,
                                                           mutationType: .update,
                                                           createdAt: .now(),
                                                           version: 1,
                                                           inProcess: true)
        let pendingMutationEvent = try createMutationEvent(model: post2,
                                                           mutationType: .update,
                                                           createdAt: .now().add(value: 1, to: .second),
                                                           version: 1)
        let responseMutationSync = createMutationSync(model: post3, version: 2)

        setUpPendingMutationQueue(modelId, [requestMutationEvent, pendingMutationEvent], pendingMutationEvent)

        let reconciledEvent = MutationEvent.reconcile(pendingMutationEvent: pendingMutationEvent,
                                                      with: requestMutationEvent,
                                                      responseMutationSync: responseMutationSync)
        XCTAssertNil(reconciledEvent)

        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 1")
        let updatingVersionExpectation =
            expectation(description: "don't update latest mutation event with response version")

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

    /// - Given: A pending mutation events queue with event containing version 1, a sent mutation event model
    ///         that matches the received mutation sync model having version 1. The received mutation sync
    ///         has version 2.
    /// - When: The sent model matches the received model and the first pending mutation event version is 1.
    /// - Then: The first pending mutation event version should be updated to received mutation sync version i.e. 2.
    func testPendingVersionReconciledSuccess() throws {
        throw XCTSkip("TODO: fix this test")
        let modelId = UUID().uuidString
        let post1 = Post(id: modelId, title: "title1", content: "content1", createdAt: .now())
        let post2 = Post(id: modelId, title: "title2", content: "content2", createdAt: .now())
        let requestMutationEvent = try createMutationEvent(model: post1,
                                                           mutationType: .update,
                                                           createdAt: .now(),
                                                           version: 1,
                                                           inProcess: true)
        let pendingMutationEvent = try createMutationEvent(model: post2,
                                                           mutationType: .update,
                                                           createdAt: .now().add(value: 1, to: .second),
                                                           version: 1)
        let responseMutationSync = createMutationSync(model: post1, version: 2)

        setUpPendingMutationQueue(modelId, [requestMutationEvent, pendingMutationEvent], pendingMutationEvent)

        let reconciledEvent = MutationEvent.reconcile(pendingMutationEvent: pendingMutationEvent,
                                                      with: requestMutationEvent,
                                                      responseMutationSync: responseMutationSync)
        XCTAssertNotNil(reconciledEvent)
        XCTAssertEqual(reconciledEvent?.version, responseMutationSync.syncMetadata.version)

        let queryAfterUpdatingVersionExpectation = expectation(description: "update mutation should have version 2")
        let updatingVersionExpectation = expectation(description: "update latest mutation event with response version")

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

    private func createMutationEvent(model: Model,
                                     mutationType: MutationEvent.MutationType,
                                     createdAt: Temporal.DateTime,
                                     version: Int? = nil,
                                     inProcess: Bool = false) throws -> MutationEvent {
        return MutationEvent(id: UUID().uuidString,
                             modelId: model.id,
                             modelName: model.modelName,
                             json: try model.toJSON(),
                             mutationType: mutationType,
                             createdAt: createdAt,
                             version: version,
                             inProcess: inProcess)
    }

    private func createMutationSync(model: Model, version: Int = 1) -> MutationSync<AnyModel> {
        let metadata = MutationSyncMetadata(modelId: model.id,
                                            modelName: model.modelName,
                                            deleted: false,
                                            lastChangedAt: Int(Date().timeIntervalSince1970),
                                            version: version)
        return MutationSync(model: AnyModel(model), syncMetadata: metadata)
    }

    private func setUpPendingMutationQueue(_ modelId: String,
                                           _ mutationEvents: [MutationEvent],
                                           _ expectedHeadOfQueue: MutationEvent) {
        for mutationEvent in mutationEvents {
            let mutationEventSaveExpectation = expectation(description: "save mutation event success")
            storageAdapter.save(mutationEvent) { result in
                guard case .success = result else {
                    XCTFail("Failed to save metadata")
                    return
                }
                mutationEventSaveExpectation.fulfill()
            }
            wait(for: [mutationEventSaveExpectation], timeout: 1)
        }

        // verify the head of queue is expected
        let headOfQueueExpectation = expectation(description: "head of mutation event queue is as expected")
        MutationEvent.pendingMutationEvents(for: modelId,
                                            storageAdapter: storageAdapter) { result in
            switch result {
            case .failure(let error):
                XCTFail("Error : \(error)")
            case .success(let events):
                guard !events.isEmpty, let head = events.first else {
                    XCTFail("Failure while fetching mutation events")
                    return
                }
                XCTAssertEqual(head, expectedHeadOfQueue)
                headOfQueueExpectation.fulfill()
            }
        }
        wait(for: [headOfQueueExpectation], timeout: 1)
    }
}
