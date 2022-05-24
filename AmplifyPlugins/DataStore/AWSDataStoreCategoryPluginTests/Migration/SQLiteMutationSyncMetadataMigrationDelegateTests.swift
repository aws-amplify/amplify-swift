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

class SQLiteMutationSyncMetadataMigrationDelegateTests: MutationSyncMetadataMigrationTestBase {

    // MARK: - Clear tests

    func testClearSuccess() throws {
        try setUpAllModels()
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        try delegate.emptyMutationSyncMetadataStore()
        try delegate.emptyModelSyncMetadataStore()
    }

    /// Ensure the deleted MutationSyncMetadata table is query-ably and empty after deleting all the records
    func testDeleteMutationSyncMetadata() throws {
        try setUpAllModels()
        let metadata = MutationSyncMetadata(modelId: "1", modelName: "2", deleted: false, lastChangedAt: 1, version: 1)
        save(metadata)
        guard let mutationSyncMetadatas = queryMutationSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertEqual(mutationSyncMetadatas.count, 1)

        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        let sql = try delegate.emptyMutationSyncMetadataStore()
        XCTAssertEqual(sql, "delete from \"MutationSyncMetadata\" as root")
        guard let mutationSyncMetadatas = queryMutationSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertTrue(mutationSyncMetadatas.isEmpty)
    }

    /// Ensure the deleted ModelSyncMetadata table is query-ably and empty after deleting all the records
    func testDeleteModelSyncMetadata() throws {
        try setUpAllModels()
        let metadata = ModelSyncMetadata(id: "modelName", lastSync: 1)
        save(metadata)
        guard let modelSyncMetadatas = queryModelSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertEqual(modelSyncMetadatas.count, 1)

        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        let sql = try delegate.emptyModelSyncMetadataStore()
        XCTAssertEqual(sql, "delete from \"ModelSyncMetadata\" as root")
        guard let modelSyncMetadatasDeleted = queryModelSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertTrue(modelSyncMetadatasDeleted.isEmpty)
    }

    // MARK: - Migration tests

    func testMigrate() throws {
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

        try delegate.removeMutationSyncMetadataCopyStore()
        try delegate.createMutationSyncMetadataCopyStore()
        try delegate.backfillMutationSyncMetadata()
        try delegate.removeMutationSyncMetadataStore()
        try delegate.renameMutationSyncMetadataCopy()

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

    /// Ensure creating and dropping the MutationSyncMetadataCopy works as expected
    func testDropMutationSyncMetadataCopyIfExists() throws {
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        try delegate.removeMutationSyncMetadataCopyStore()

        // Dropping the table without the table in the database is successful
        let drop = try delegate.removeMutationSyncMetadataCopyStore()

        XCTAssertEqual(drop, """
        DROP TABLE IF EXISTS "MutationSyncMetadataCopy"
        """)

        // Creating the table is successful
        let create = try delegate.createMutationSyncMetadataCopyStore()
        let exectedCreateSQL = """
        create table if not exists "MutationSyncMetadataCopy" (
          "id" text primary key not null,
          "deleted" integer not null,
          "lastChangedAt" integer not null,
          "version" integer not null
        );
        """
        XCTAssertEqual(create, exectedCreateSQL)

        // A second create does not throw if the table has already been created
        try delegate.createMutationSyncMetadataCopyStore()

        // A drop is successful when the table has been created
        try delegate.removeMutationSyncMetadataCopyStore()

        // Dropping twice is successfully
        try delegate.removeMutationSyncMetadataCopyStore()
    }

}
