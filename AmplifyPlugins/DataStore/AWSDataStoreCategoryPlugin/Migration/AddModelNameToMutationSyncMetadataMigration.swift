//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite
import AWSPluginsCore

class AddModelNameToMutationSyncMetadataMigration: ModelMigration {

    let connection: Connection
    let modelSchemas: [ModelSchema]

    init(connection: Connection, modelSchemas: [ModelSchema]) {
        self.connection = connection
        self.modelSchemas = modelSchemas
    }

    func apply() throws {
        try connection.transaction {
            let metadataCounts = try selectMutationSyncMetadataRecords()
            guard needsMigration(metadataCount: metadataCounts.metadataCount,
                                 metadataIdMatchNewKeyCount: metadataCounts.metadataIdMatchNewKeyCount) else {
                    log.debug("No MutationSyncMetadata migration needed.")
                    return
            }
            log.debug("Migration is needed. MutationSyncMetadata IDs need to be migrated to new key format.")
            if try containsDuplicateIdsAcrossModels() {
                log.debug("""
                Duplicate IDs found across different model types.
                Clearing MutationSyncMetadata and ModelSyncMetadata to force full sync.
                """)
                try deleteMutationSyncMetadata()
                try deleteModelSyncMetadata()
            } else {
                log.debug("No duplicate IDs found. Modifying and backfilling MutationSyncMetadata")
                try dropMutationSyncMetadataCopyIfExists()
                try createMutationSyncMetadataCopyTable()
                try backfillMutationSyncMetadata()
                try dropMutationSyncMetadata()
                try renameMutationSyncMetadataCopy()
            }
        }
    }

    // MARK: - Delete Tables

    @discardableResult func deleteMutationSyncMetadata() throws -> String {
        let deleteStatement = DeleteStatement(modelSchema: MutationSyncMetadata.schema).stringValue
        try connection.execute(deleteStatement)
        return deleteStatement
    }

    @discardableResult func deleteModelSyncMetadata() throws -> String {
        let deleteStatement = DeleteStatement(modelSchema: ModelSyncMetadata.schema).stringValue
        try connection.execute(deleteStatement)
        return deleteStatement
    }

    // MARK: - Migration

    @discardableResult func dropMutationSyncMetadataCopyIfExists() throws -> String {
        let dropStatement = DropTableStatement(modelSchema: MutationSyncMetadataCopy.schema).stringValue
        try connection.execute(dropStatement)
        return dropStatement
    }

    @discardableResult func createMutationSyncMetadataCopyTable() throws -> String {
        let createTableStatement = CreateTableStatement(modelSchema: MutationSyncMetadataCopy.schema).stringValue
        try connection.execute(createTableStatement)
        return createTableStatement
    }

    @discardableResult  func backfillMutationSyncMetadata() throws -> String {
        var sql = ""
        for modelSchema in modelSchemas {
            let modelName = modelSchema.name

            if sql != "" {
                sql += " UNION ALL "
            }
            sql += "SELECT id, \'\(modelName)\' as tableName FROM \(modelName)"
        }
        sql = "INSERT INTO \(MutationSyncMetadataCopy.modelName) (id,deleted,lastChangedAt,version) " +
        "select models.tableName || '|' || mm.id, mm.deleted, mm.lastChangedAt, mm.version " +
        "from MutationSyncMetadata mm INNER JOIN (" + sql + ") as models on mm.id=models.id"
        try connection.execute(sql)
        return sql
    }

    @discardableResult func dropMutationSyncMetadata() throws -> String {
        let dropStatement = DropTableStatement(modelSchema: MutationSyncMetadata.schema).stringValue
        try connection.execute(dropStatement)
        return dropStatement
    }

    @discardableResult func renameMutationSyncMetadataCopy() throws -> String {
        let alterTableStatement = "ALTER TABLE \(MutationSyncMetadataCopy.modelName) RENAME TO \(MutationSyncMetadata.modelName)"
        try connection.execute(alterTableStatement)
        return alterTableStatement
    }
}
extension AddModelNameToMutationSyncMetadataMigration: DefaultLogger { }

