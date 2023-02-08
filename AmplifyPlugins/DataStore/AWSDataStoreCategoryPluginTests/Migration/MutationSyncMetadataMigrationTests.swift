//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class MutationSyncMetadataMigrationTests: MutationSyncMetadataMigrationTestBase {

    func testApply_MissingDelegate() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        migration.delegate = nil

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_PreconditionFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.preconditionCheckError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_TransactionFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.transactionError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition, .transaction])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_NeedsMigrationFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.mutationSyncMetadataStoreEmptyOrMigratedError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled,
                           [.precondition, .transaction, .mutationSyncMetadataStoreEmptyOrMigrated])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_CannotMigrateFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.containsDuplicateIdsAcrossModelsError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                                  .transaction,
                                                  .mutationSyncMetadataStoreEmptyOrMigrated,
                                                  .containsDuplicateIdsAcrossModels])

            return
        }
        XCTFail("Should catch error")
    }

    func testApply_emptyMutationSyncMetadataStoreFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.containsDuplicateIdsAcrossModelsResult = true
        delegate.emptyMutationSyncMetadataStoreError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                                  .transaction,
                                                  .mutationSyncMetadataStoreEmptyOrMigrated,
                                                  .containsDuplicateIdsAcrossModels,
                                                  .emptyMutationSyncMetadataStore])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_emptyModelSyncMetadataStoreFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.containsDuplicateIdsAcrossModelsResult = true
        delegate.emptyModelSyncMetadataStoreError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                                  .transaction,
                                                  .mutationSyncMetadataStoreEmptyOrMigrated,
                                                  .containsDuplicateIdsAcrossModels,
                                                  .emptyMutationSyncMetadataStore,
                                                  .emptyModelSyncMetadataStore])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_MigrateFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.mutationSyncMetadataStoreEmptyOrMigratedResult = false
        delegate.containsDuplicateIdsAcrossModelsResult = false
        delegate.removeMutationSyncMetadataCopyStoreError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                                  .transaction,
                                                  .mutationSyncMetadataStoreEmptyOrMigrated,
                                                  .containsDuplicateIdsAcrossModels,
                                                  .removeMutationSyncMetadataCopyStore])
            return
        }
        XCTFail("Should catch error")
    }

    func testApplyMigrate() throws {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.mutationSyncMetadataStoreEmptyOrMigratedResult = false
        delegate.containsDuplicateIdsAcrossModelsResult = false
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        try migration.apply()
        XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                              .transaction,
                                              .mutationSyncMetadataStoreEmptyOrMigrated,
                                              .containsDuplicateIdsAcrossModels,
                                              .removeMutationSyncMetadataCopyStore,
                                              .createMutationSyncMetadataCopyStore,
                                              .backfillMutationSyncMetadata,
                                              .removeMutationSyncMetadataStore,
                                              .renameMutationSyncMetadataCopy])
    }

    func testApply() throws {
        try setUpAllModels()
        let restaurant = Restaurant(restaurantName: "name")
        save(restaurant)
        let metadata = MutationSyncMetadata(id: restaurant.id, deleted: false, lastChangedAt: 1, version: 1)
        saveMutationSyncMetadata(metadata)
        guard let mutationSyncMetadatas = queryMutationSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertEqual(mutationSyncMetadatas.count, 1)
        XCTAssertEqual(mutationSyncMetadatas[0].id, restaurant.id)

        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        try migration.apply()

        guard let mutationSyncMetadatasBackfilled = queryMutationSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertEqual(mutationSyncMetadatasBackfilled.count, 1)

        XCTAssertEqual(mutationSyncMetadatasBackfilled[0].id, "\(Restaurant.modelName)|\(restaurant.id)")

        guard let restaurantMetadata = try storageAdapter.queryMutationSyncMetadata(
            for: restaurant.id,
               modelName: Restaurant.modelName) else {
                   XCTFail("Could not get metadata")
                   return
               }
        XCTAssertEqual(restaurantMetadata.modelId, restaurant.id)
        XCTAssertEqual(restaurantMetadata.modelName, Restaurant.modelName)
    }

    func testApplyClear() throws {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.mutationSyncMetadataStoreEmptyOrMigratedResult = false
        delegate.containsDuplicateIdsAcrossModelsResult = true
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        try migration.apply()
        XCTAssertEqual(delegate.stepsCalled, [.precondition,
                                              .transaction,
                                              .mutationSyncMetadataStoreEmptyOrMigrated,
                                              .containsDuplicateIdsAcrossModels,
                                              .emptyMutationSyncMetadataStore,
                                              .emptyModelSyncMetadataStore])
    }
}
