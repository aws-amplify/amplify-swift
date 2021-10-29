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

extension AddModelNameToMutationSyncMetadataMigration {

    // MARK: - Validation

    /// Retrieve the record count from the MutationSyncMetadata table for
    ///     1. the total number of records
    ///     2. the total number of records that have the `id` match `<modelName>|<modelId>`
    func selectMutationSyncMetadataRecords() throws -> (metadataCount: Int64, metadataIdMatchNewKeyCount: Int64) {
        let sql = """
        select (select count(1) as count from MutationSyncMetadata) as allRecords,
        (select count(1) as count from MutationSyncMetadata where id like '%|%') as newKeys
        """
        log.debug("Checking MutationSyncMetadata records, SQL: \(sql)")
        let rows = try connection.run(sql)
        let iter = rows.makeIterator()
        while let row = try iter.failableNext() {
            if let metadataCount = row[0] as? Int64, let metadataIdMatchNewKeyCount = row[1] as? Int64 {
                return (metadataCount, metadataIdMatchNewKeyCount)
            } else {
                log.verbose("")
                throw DataStoreError.unknown("", "", nil)
            }
        }

        throw DataStoreError.unknown("", "", nil)
    }

    /// If there are no MutationSyncMetadata records, then it is not necessary to apply the migration since there is no
    /// data to migrate. If there is data, and the id's have already been migrated ( > 0 keys), then no migration needed
    func needsMigration(metadataCount: Int64, metadataIdMatchNewKeyCount: Int64) -> Bool {
        if metadataCount == 0 || metadataIdMatchNewKeyCount > 0 {
            return false
        }
        return true
    }

    func selectDuplicateIdAcrossModels() -> String {
        var sql = ""
        for modelSchema in modelSchemas {
            let modelName = modelSchema.name
            if sql != "" {
                sql += " UNION ALL "
            }
            sql += "SELECT id, \'\(modelName)\' as tableName FROM \(modelName)"
        }
        return "SELECT id, tableName, count(id) as count FROM (" + sql + ") GROUP BY id HAVING count > 1"
    }

    /// Retrieve results where `id` is the same across multiple tables.
    /// For three models, the SQL statement looks like this:
    /// ```
    /// SELECT id, tableName, count(id) as count FROM (
    ///    SELECT id, 'Restaurant' as tableName FROM Restaurant UNION ALL
    ///    SELECT id, 'Menu' as tableName FROM Menu UNION ALL
    ///    SELECT id, 'Dish' as tableName FROM Dish) GROUP BY id HAVING count > 1
    /// ```
    /// If there are three models in different model tables with the same id "1"
    /// the result of this query will have a row like:
    /// ```
    /// // [id, tableName, count(id)
    /// [Optional("1"), Optional("Restaurant"), Optional(3)]
    /// ```
    /// As long as there is one resulting duplicate id, the entire function will return true
    func containsDuplicateIdsAcrossModels() throws -> Bool {
        let sql = selectDuplicateIdAcrossModels()
        log.debug("Checking for duplicate IDs, SQL: \(sql)")
        let rows = try connection.run(sql)
        let iter = rows.makeIterator()
        while let row = try iter.failableNext() {
            return !row.isEmpty
        }

        return false
    }
}
