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
@testable import AWSDataStorePlugin
@testable import AWSPluginsCore
import SQLite3

class SQLiteMutationSyncMetadataMigrationValidationTests: MutationSyncMetadataMigrationTestBase {

    // MARK: - Precondition tests
    func testPreconditionSuccess() throws {
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        try delegate.preconditionCheck()
    }

    // MARK: - Needs Migration tests

    func testSelectMutationSyncMetadataWithoutTableShouldThrow() {
        let shouldCatchFailure = expectation(description: "select MutationSyncMetadata without table should fail")
        do {
            let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                       modelSchemas: modelSchemas)
            _ = try delegate.selectMutationSyncMetadataRecords()
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
    func testMutationSyncMetadataStoreIsNotEmptyAndNotMigrated() throws {
        try setUpAllModels()
        let metadata = MutationSyncMetadata(id: UUID().uuidString, deleted: false, lastChangedAt: 1, version: 1)
        save(metadata)
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)

        XCTAssertFalse(try delegate.mutationSyncMetadataStoreEmptyOrMigrated())
    }

    /// Set up MutationSyncMetadata records where the id is in the correct format. Check that it does not need migration
    func testMutationSyncMetadataStoreNotEmptyAndMigrated() throws {
        try setUpAllModels()
        let metadata = MutationSyncMetadata(modelId: UUID().uuidString,
                                            modelName: "modelName",
                                            deleted: false,
                                            lastChangedAt: 1,
                                            version: 1)
        save(metadata)
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)

        XCTAssertTrue(try delegate.mutationSyncMetadataStoreEmptyOrMigrated())
    }

    // MARK: - Cannot Migrate tests

    func testSelectDuplicateIdCountAcrossModelsWithoutTableShouldThrow() {
        let shouldCatchFailure = expectation(description: "select duplicate id count without model tables should fail")
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        do {
            _ = try delegate.containsDuplicateIdsAcrossModels()
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
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        let expected = "SELECT id, tableName, count(id) as count FROM " +
        "(SELECT id, 'Restaurant' as tableName FROM Restaurant UNION ALL " +
        "SELECT id, 'Menu' as tableName FROM Menu UNION ALL " +
        "SELECT id, 'Dish' as tableName FROM Dish) GROUP BY id HAVING count > 1"
        XCTAssertEqual(delegate.selectDuplicateIdAcrossModels(), expected)
    }

    func testSelectDuplicateIdCountAcrossModels_NoData() throws {
        try setUpAllModels()
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        XCTAssertFalse(try delegate.containsDuplicateIdsAcrossModels())
    }

    func testSelectDuplicateIdCountAcrossModels_ModelWithUniqueIds() throws {
        try setUpAllModels()
        let restaurant = Restaurant(restaurantName: "name")
        save(restaurant)
        let menu = Menu(name: "name", restaurant: restaurant)
        save(menu)
        let dish = Dish(dishName: "name", menu: menu)
        save(dish)
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        XCTAssertFalse(try delegate.containsDuplicateIdsAcrossModels())
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
        let delegate = SQLiteMutationSyncMetadataMigrationDelegate(storageAdapter: storageAdapter,
                                                                   modelSchemas: modelSchemas)
        XCTAssertTrue(try delegate.containsDuplicateIdsAcrossModels())
    }
}
