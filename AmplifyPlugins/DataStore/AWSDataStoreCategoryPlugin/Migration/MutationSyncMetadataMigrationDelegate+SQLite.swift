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

final class SQLiteMutationSyncMetadataMigrationDelegate: MutationSyncMetadataMigrationDelegate {

    let modelSchemas: [ModelSchema]
    weak var storageAdapter: SQLiteStorageEngineAdapter?

    init(storageAdapter: SQLiteStorageEngineAdapter, modelSchemas: [ModelSchema]) {
        self.storageAdapter = storageAdapter
        self.modelSchemas = modelSchemas
    }

    func transaction(_ basicClosure: BasicThrowableClosure) throws {
        try storageAdapter?.transaction(basicClosure)
    }

    // MARK: - Clear

    func clear() throws {
        log.debug("Clearing MutationSyncMetadata and ModelSyncMetadata to force full sync.")
        try deleteMutationSyncMetadata()
        try deleteModelSyncMetadata()
    }

    @discardableResult func deleteMutationSyncMetadata() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.emptyStore(for: MutationSyncMetadata.schema)
    }

    @discardableResult func deleteModelSyncMetadata() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.emptyStore(for: ModelSyncMetadata.schema)
    }

    // MARK: - Migration

    @discardableResult func removeMutationSyncMetadataCopyStore() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.removeStore(for: MutationSyncMetadataMigration.MutationSyncMetadataCopy.schema)
    }

    @discardableResult func createMutationSyncMetadataCopyStore() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.createStore(for: MutationSyncMetadataMigration.MutationSyncMetadataCopy.schema)
    }

    @discardableResult func backfillMutationSyncMetadata() throws -> String {
        var sql = ""
        for modelSchema in modelSchemas {
            let modelName = modelSchema.name

            if sql != "" {
                sql += " UNION ALL "
            }
            sql += "SELECT id, \'\(modelName)\' as tableName FROM \(modelName)"
        }
        sql = "INSERT INTO \(MutationSyncMetadataMigration.MutationSyncMetadataCopy.modelName) (id,deleted,lastChangedAt,version) " +
        "select models.tableName || '|' || mm.id, mm.deleted, mm.lastChangedAt, mm.version " +
        "from MutationSyncMetadata mm INNER JOIN (" + sql + ") as models on mm.id=models.id"
        try storageAdapter?.connection.execute(sql)
        return sql
    }

    @discardableResult func removeMutationSyncMetadataStore() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.removeStore(for: MutationSyncMetadata.schema)
    }

    @discardableResult func renameMutationSyncMetadataCopy() throws -> String {
        guard let storageAdapter = storageAdapter else {
            log.debug("Missing SQLiteStorageEngineAdapter")
            throw DataStoreError.unknown("Missing storage adapter for model migration", "", nil)
        }

        return try storageAdapter.renameStore(from: MutationSyncMetadataMigration.MutationSyncMetadataCopy.schema,
                                              toModelSchema: MutationSyncMetadata.schema)
    }
}

extension SQLiteMutationSyncMetadataMigrationDelegate: DefaultLogger { }
