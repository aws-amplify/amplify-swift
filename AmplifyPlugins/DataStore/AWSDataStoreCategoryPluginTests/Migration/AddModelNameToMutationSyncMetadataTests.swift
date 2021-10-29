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

class AddModelNameToMutationSyncMetadataTests: AddModelNameToMutationSyncMetadataTestBase {

    // MARK: - Delete tables

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

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        let sql = try migration.deleteMutationSyncMetadata()
        XCTAssertEqual(sql, "delete from MutationSyncMetadata as root")
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

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        let sql = try migration.deleteModelSyncMetadata()
        XCTAssertEqual(sql, "delete from ModelSyncMetadata as root")
        guard let modelSyncMetadatasDeleted = queryModelSyncMetadata() else {
            XCTFail("Could not get metadata")
            return
        }
        XCTAssertTrue(modelSyncMetadatasDeleted.isEmpty)
    }

    // MARK: - Migration

    /// Ensure creating and dropping the MutationSyncMetadataCopy works as expected
    func testDropMutationSyncMetadataCopyIfExists() throws {
        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        try migration.dropMutationSyncMetadataCopyIfExists()

        // Dropping the table without the table in the database is successful
        let drop = try migration.dropMutationSyncMetadataCopyIfExists()

        XCTAssertEqual(drop, "DROP TABLE IF EXISTS MutationSyncMetadataCopy")

        // Creating the table is successful
        let create = try migration.createMutationSyncMetadataCopyTable()
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
        try migration.createMutationSyncMetadataCopyTable()

        // A drop is successful when the table has been created
        try migration.dropMutationSyncMetadataCopyIfExists()

        // Dropping twice is successfully
        try migration.dropMutationSyncMetadataCopyIfExists()
    }

    func testBackfillMutationSyncMetadata() throws {
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

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        try migration.dropMutationSyncMetadataCopyIfExists()
        try migration.createMutationSyncMetadataCopyTable()
        try migration.backfillMutationSyncMetadata()
        try migration.dropMutationSyncMetadata()
        try migration.renameMutationSyncMetadataCopy()

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
}
