//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class RemoteSyncReconcilerTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    // swiftlint:disable:next force_try
    let remoteMockSynced = try! MockSynced().eraseToAnyModel()

    let mutationEvent = MutationEvent(id: "mutation-1",
                                      modelId: "local-model-1",
                                      modelName: MockSynced.modelName,
                                      json: "{}",
                                      mutationType: .create,
                                      createdAt: .now(),
                                      version: 1,
                                      inProcess: false)

    // MARK: - No local model, no pending mutations

    func testCreatedOnRemote_noLocal_noPendingMutation() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    func testUpdatedOnRemote_noLocal_noPendingMutation() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    func testDeletedOnRemote_noLocal_noPendingMutation() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    // MARK: - No local model, with pending mutations

    func testCreatedOnRemote_noLocal_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    func testUpdatedOnRemote_noLocal_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    func testDeletedOnRemote_noLocal_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // MARK: - With local model having lower version, no pending mutations

    // "Create" doesn't really have a "lower" version case, so we'll test equal versions
    func testCreatedOnRemote_withLocalEqualVersion_noPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    func testUpdatedOnRemote_withLocalLowerVersion_noPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    func testDeletedOnRemote_withLocalLowerVersion_noPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel))
    }

    // MARK: - With local model having higher version, no pending mutations

    // Create and update are both treated the same
    func testMutatedOnRemote_withLocalHigherVersion_noPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 2)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // This shouldn't be possible except in case of an error (either the service side did not properly resolve a
    // conflict updating a deleted record, or the client is incorrectly manipulating the version
    func testDeletedOnRemote_withLocalHigherVersion_noPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 2)
        let pendingMutations: [MutationEvent] = []

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // MARK: - With local model having lower version, with pending mutations

    // Create and update are both treated the same
    func testMutatedOnRemote_withLocalLowerVersion_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    func testDeletedOnRemote_withLocalLowerVersion_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // MARK: - With local model having higher version, with pending mutations

    // Create and update are both treated the same
    func testMutatedOnRemote_withLocalHigherVersion_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 3)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    func testDeletedOnRemote_withLocalHigherVersion_withPendingMutations() throws {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 3)
        let pendingMutations: [MutationEvent] = [mutationEvent]

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata,
                                                         pendingMutations: pendingMutations)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // MARK: - Utilities

    private func makeMutationSyncMetadata(deleted: Bool, version: Int) -> MutationSyncMetadata {
        let remoteSyncMetadata = MutationSyncMetadata(id: remoteMockSynced.id,
                                                      deleted: deleted,
                                                      lastChangedAt: Date().unixSeconds,
                                                      version: version)
        return remoteSyncMetadata
    }

    private func makeRemoteModel(deleted: Bool, version: Int) -> ReconcileAndLocalSaveOperation.RemoteModel {
        let remoteSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)
        let remoteModel = ReconcileAndLocalSaveOperation.RemoteModel(model: remoteMockSynced,
                                                                     syncMetadata: remoteSyncMetadata)
        return remoteModel
    }

}
