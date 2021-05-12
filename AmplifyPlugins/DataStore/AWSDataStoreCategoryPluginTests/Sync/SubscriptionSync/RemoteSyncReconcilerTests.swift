//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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

    // MARK: pending mutations

    func testShouldDrop_noPendingMutations() {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = []
        let shouldDrop = RemoteSyncReconciler.shouldDropRemoteModel(remoteModel, pendingMutations: pendingMutations)

        XCTAssertFalse(shouldDrop)
    }

    func testShouldDrop_withPendingMutations() {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let pendingMutations: [MutationEvent] = [mutationEvent]
        let shouldDrop = RemoteSyncReconciler.shouldDropRemoteModel(remoteModel, pendingMutations: pendingMutations)

        XCTAssertTrue(shouldDrop)
    }

    // MARK: - No local model

    func testCreatedOnRemote_noLocal() {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .create))
    }

    func testUpdatedOnRemote_noLocal() {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .create))
    }

    func testDeletedOnRemote_noLocal() {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: nil)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .create))
    }

    // MARK: - With local model having lower version

    // "Create" doesn't really have a "lower" version case, so we'll test equal versions
    func testCreatedOnRemote_withLocalEqualVersion() {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .update))
    }

    func testUpdatedOnRemote_withLocalLowerVersion() {
        let remoteModel = makeRemoteModel(deleted: false, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .update))
    }

    func testDeletedOnRemote_withLocalLowerVersion() {
        let remoteModel = makeRemoteModel(deleted: true, version: 2)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 1)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.applyRemoteModel(remoteModel, .update))
    }

    // MARK: - With local model having higher version

    // Create and update are both treated the same
    func testMutatedOnRemote_withLocalHigherVersion_noPendingMutations() {
        let remoteModel = makeRemoteModel(deleted: false, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 2)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata)

        XCTAssertEqual(disposition, RemoteSyncReconciler.Disposition.dropRemoteModel("MockSynced"))
    }

    // This shouldn't be possible except in case of an error (either the service side did not properly resolve a
    // conflict updating a deleted record, or the client is incorrectly manipulating the version
    func testDeletedOnRemote_withLocalHigherVersion() {
        let remoteModel = makeRemoteModel(deleted: true, version: 1)
        let localSyncMetadata = makeMutationSyncMetadata(deleted: false, version: 2)

        let disposition = RemoteSyncReconciler.reconcile(remoteModel: remoteModel,
                                                         to: localSyncMetadata)

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
