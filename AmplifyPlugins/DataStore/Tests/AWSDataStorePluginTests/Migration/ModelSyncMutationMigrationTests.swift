//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SQLite

@testable import Amplify
@testable import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

final class ModelSyncMetadataMigrationTests: XCTestCase {

    var connection: Connection!
    var storageEngine: StorageEngine!
    var storageAdapter: SQLiteStorageEngineAdapter!
    var dataStorePlugin: AWSDataStorePlugin!
    
    override func setUp() async throws {
        await Amplify.reset()
        
        do {
            connection = try Connection(.inMemory)
            storageAdapter = try SQLiteStorageEngineAdapter(connection: connection)
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }
    
    /// Use the latest schema and create the table with it.
    /// The column should be found and no upgrade should occur.
    func testPerformModelMetadataSyncPredicateUpgrade_ColumnExists() throws {
        try storageAdapter.setUp(modelSchemas: StorageEngine.systemModelSchemas)
        guard let field = ModelSyncMetadata.schema.field(
            withName: ModelSyncMetadata.keys.syncPredicate.stringValue) else {
            XCTFail("Could not find corresponding ModelField from ModelSyncMetadata for syncPredicate")
            return
        }
        let modelSyncMetadataMigration = ModelSyncMetadataMigration(storageAdapter: storageAdapter)
        
        let exists = try modelSyncMetadataMigration.columnExists(modelSchema: ModelSyncMetadata.schema, field: field)
        XCTAssertTrue(exists)
        
        do {
            let result = try modelSyncMetadataMigration.performModelMetadataSyncPredicateUpgrade()
            XCTAssertFalse(result)
        } catch {
            XCTFail("Failed to perform upgrade \(error)")
        }
    }
    
    /// Create a local copy of the previous ModelSyncMetadata, without sync predicate
    /// Create the table with the previous schema, and perform the upgrade.
    /// The upgrade should have occurred successfully.
    func testPerformModelMetadataSyncPredicateUpgrade_ColumnDoesNotExist() throws {
        struct ModelSyncMetadata: Model {
            public let id: String
            public var lastSync: Int?
            
            public init(id: String,
                        lastSync: Int?) {
                self.id = id
                self.lastSync = lastSync
            }
            public enum CodingKeys: String, ModelKey {
                case id
                case lastSync
            }
            public static let keys = CodingKeys.self
            public static let schema = defineSchema { definition in
                definition.attributes(.isSystem)
                definition.fields(
                    .id(),
                    .field(keys.lastSync, is: .optional, ofType: .int)
                )
            }
        }

        try storageAdapter.setUp(modelSchemas: [ModelSyncMetadata.schema])
        guard let field = AWSPluginsCore.ModelSyncMetadata.schema.field(
            withName: AWSPluginsCore.ModelSyncMetadata.keys.syncPredicate.stringValue) else {
            XCTFail("Could not find corresponding ModelField from ModelSyncMetadata for syncPredicate")
            return
        }
        let modelSyncMetadataMigration = ModelSyncMetadataMigration(storageAdapter: storageAdapter)
        let exists = try modelSyncMetadataMigration.columnExists(modelSchema: AWSPluginsCore.ModelSyncMetadata.schema, field: field)
        XCTAssertFalse(exists)
        
        do {
            let result = try modelSyncMetadataMigration.performModelMetadataSyncPredicateUpgrade()
            XCTAssertTrue(result)
        } catch {
            XCTFail("Failed to perform upgrade \(error)")
        }
    }
}
