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

class AddModelNameToMutationSyncMetadataValidationTests: AddModelNameToMutationSyncMetadataTestBase {

    func testSelectMutationSyncMetadataWithoutTableShouldThrow() {
        let shouldCatchFailure = expectation(description: "select MutationSyncMetadata without table should fail")
        do {
            let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection,
                                                                        modelSchemas: modelSchemas)
            _ = try migration.selectMutationSyncMetadataRecords()
        } catch {
            guard let resultError = error as? Result,
                  case .error(let message, let code, _) = resultError else {
                      XCTFail("Unexpected error: \(error)")
                      return
                  }

            XCTAssertEqual(code, SQLITE_ERROR)
            XCTAssertEqual(message, "no such table: MutationSyncMetadata")
            shouldCatchFailure.fulfill()
        }
        wait(for: [shouldCatchFailure], timeout: 1)
    }

    /// Set up MutationSyncMetadata records where the id is in the incorrect format. Check that it needs migration.
    func testNeedsMigrationTrue() throws {
        try setUpAllModels()
        let metadata = MutationSyncMetadata(id: UUID().uuidString, deleted: false, lastChangedAt: 1, version: 1)
        save(metadata)

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)

        let results = try migration.selectMutationSyncMetadataRecords()
        XCTAssertTrue(migration.needsMigration(metadataCount: results.metadataCount,
                                               metadataIdMatchNewKeyCount: results.metadataIdMatchNewKeyCount))
    }

    /// Set up MutationSyncMetadata records where the id is in the correct format. Check that it does not need migration
    func testNeedMigrationFalse() throws {
        try setUpAllModels()
        let metadata = MutationSyncMetadata(modelId: UUID().uuidString,
                                            modelName: "modelName",
                                            deleted: false,
                                            lastChangedAt: 1,
                                            version: 1)
        save(metadata)

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)

        let results = try migration.selectMutationSyncMetadataRecords()
        XCTAssertFalse(migration.needsMigration(metadataCount: results.metadataCount,
                                                metadataIdMatchNewKeyCount: results.metadataIdMatchNewKeyCount))
    }

    func testSelectDuplicateIdCountAcrossModelsWithoutTableShouldThrow() {
        let shouldCatchFailure = expectation(description: "select duplicate id count without model tables should fail")
        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        do {
            _ = try migration.containsDuplicateIdsAcrossModels()
        } catch {
            guard let resultError = error as? Result,
                  case .error(let message, let code, _) = resultError else {
                      XCTFail("Unexpected error: \(error)")
                      return
                  }

            XCTAssertEqual(code, SQLITE_ERROR)
            XCTAssertEqual(message, "no such table: Dish")
            shouldCatchFailure.fulfill()
        }
        wait(for: [shouldCatchFailure], timeout: 1)
    }

    func testSelectDuplicateIdAcrossModelsStatement() throws {
        try setUpAllModels()
        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        let expected = "SELECT id, tableName, count(id) as count FROM " +
        "(SELECT id, 'Restaurant' as tableName FROM Restaurant UNION ALL " +
        "SELECT id, 'Menu' as tableName FROM Menu UNION ALL " +
        "SELECT id, 'Dish' as tableName FROM Dish) GROUP BY id HAVING count > 1"
        XCTAssertEqual(migration.selectDuplicateIdAcrossModels(), expected)
    }

    func testSelectDuplicateIdCountAcrossModels_NoData() throws {
        try setUpAllModels()
        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)

        XCTAssertFalse(try migration.containsDuplicateIdsAcrossModels())
    }

    func testSelectDuplicateIdCountAcrossModels_ModelWithUniqueIds() throws {
        try setUpAllModels()
        let restaurant = Restaurant(restaurantName: "name")
        save(restaurant)
        let menu = Menu(name: "name", restaurant: restaurant)
        save(menu)
        let dish = Dish(dishName: "name", menu: menu)
        save(dish)

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        XCTAssertFalse(try migration.containsDuplicateIdsAcrossModels())
    }

    func testSelectDuplicateIdCountAcrossModels_ModelWithDuplicateIds() throws {
        try setUpAllModels()
        let restaurant1 = Restaurant(id: "1", restaurantName: "name1")
        save(restaurant1)
        let restaurant2 = Restaurant(id: "2", restaurantName: "name2")
        save(restaurant2)
        let menu = Menu(id: "1", name: "name", restaurant: restaurant1)
        save(menu)
        let dish = Dish(id: "1", dishName: "name", menu: menu)
        save(dish)

        let migration = AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)
        XCTAssertTrue(try migration.containsDuplicateIdsAcrossModels())
    }

}
