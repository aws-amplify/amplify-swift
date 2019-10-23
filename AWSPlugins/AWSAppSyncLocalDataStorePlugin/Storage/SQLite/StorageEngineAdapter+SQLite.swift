//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// [SQLite](https://sqlite.org) `StorageEngineAdapter` implementation. This class provides
/// an integration layer between the AppSyncLocal `StorageEngine` and SQLite for local storage.
final public class SQLiteStorageEngineAdapter: StorageEngineAdapter {

    internal var connection: Connection!

    public convenience init(databaseName: String = "database") throws {
        guard let documentsPath = getDocumentPath() else {
            preconditionFailure("Could not create the database. The `.documentDirectory` is invalid")
        }
        let path = documentsPath
            .appendingPathComponent("\(databaseName).db")
            .absoluteString
        let connection = try Connection(path)
        self.init(connection: connection)
    }

    internal init(connection: Connection) {
        self.connection = connection
    }

    public func setUp(models: [PersistentModel.Type]) throws {
        let createTableStatements = models
            .sortByDependencyOrder()
            .map(getCreateTableStatement(for:))
            .joined(separator: "\n")

        // database setup statement
        let statement = """
        pragma auto_vacuum = full;
        pragma encoding = "utf-8";
        pragma foreign_keys = on;
        \(createTableStatements)
        """

        do {
            try connection.execute(statement)
        } catch {
            throw DataStoreError.invalidDatabase
        }
    }

    public func save<M: PersistentModel>(_ model: M, completion: DataStoreCallback<M>) {
        let modelType = type(of: model)
        let sql = getInsertStatement(for: modelType)
        let values = model.sqlValues(for: modelType.properties.columns())

        do {
            _ = try connection.prepare(sql).run(values)
            // TODO serialize result and create a new instance of the model
            // (some columns might be auto-generated after DB insert/update)
            completion(.result(model))
        } catch {
            completion(.failure(causedBy: error))
        }

    }

    public func query<M: PersistentModel>(_ modelType: M.Type,
                                          completion: DataStoreCallback<[M]>) {
        do {
            let statement = getSelectStatement(for: modelType)
            let rows = try connection.prepare(statement).run()
            let result: [M] = try rows.toModel()
            completion(.result(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    // MARK: - Internal

    internal func getCreateTableStatement(for modelType: PersistentModel.Type) -> String {
        let name = modelType.name
        var statement = "create table if not exists \(name) (\n"

        let properties = modelType.properties.columns()
        let foreignKeys = modelType.properties.foreignKeys()

        for (index, property) in properties.enumerated() {
            let metadata = property.metadata
            statement += "  \"\(metadata.sqlName)\" \(metadata.sqlType.rawValue)"
            if metadata.isPrimaryKey {
                statement += " primary key"
            }
            if !metadata.optional {
                statement += " not null"
            }

            if index < properties.endIndex - 1 || !foreignKeys.isEmpty {
                statement += ",\n"
            }
        }

        for foreignKey in foreignKeys {
            statement += "  foreign key(\"\(foreignKey.metadata.sqlName)\") "
            guard let connectedModel = foreignKey.metadata.connectedModel else {
                preconditionFailure(
                    """
                    Model properties that are foreign keys must be connected to another Model.
                    Check the "ModelProperty" section of your "\(name)+Metadata.swift" file.
                    """
                )
            }

            let connectedId = connectedModel.properties.first { $0.metadata.isPrimaryKey }!
            statement += "references \(connectedModel.name)(\"\(connectedId.metadata.sqlName)\")"
        }

        statement += "\n);"
        return statement
    }

    internal func getInsertStatement(for modelType: PersistentModel.Type) -> String {
        let properties = modelType.properties.columns()
        let columns = properties.map { $0.metadata.columnName() }
        var statement = "insert into \(modelType.name) "
        statement += "(\(columns.joined(separator: ", ")))\n"

        let valuePlaceholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        statement += "values (\(valuePlaceholders))"

        // update if id exists (aka upsert)
//        statement += "\non conflict(\(model.primaryKey.metadata.sqlName)) do update set"
//        for prop in properties where !prop.metadata.isPrimaryKey {
//            let name = prop.metadata.sqlName
//            statement += "\n  \(name) = excluded.\(name)"
//        }

        return statement
    }

    internal func getSelectStatement(for modelType: PersistentModel.Type) -> String {
        let properties = modelType.properties.columns()
        let tableName = modelType.name
        var columns = properties.map { prop -> String in
            return prop.metadata.columnName(forNamespace: "root") + " " + prop.metadata.columnAlias()
        }

        // eager load many-to-one relationships (simple inner join)
        var joinStatements: [String] = []
        for foreignKey in modelType.properties.foreignKeys() {
            let connectedModelType = foreignKey.metadata.connectedModel!
            let connectedTableName = connectedModelType.name

            // columns
            let alias = foreignKey.metadata.name
            let connectedColumn = connectedModelType.primaryKey.metadata.columnName(forNamespace: alias)
            let foreignKeyName = foreignKey.metadata.columnName(forNamespace: "root")

            // append columns from relationships
            columns += connectedModelType.properties.columns().map { prop -> String in
                let metadata = prop.metadata
                return metadata.columnName(forNamespace: alias) + " " + metadata.columnAlias(forNamespace: alias)
            }

            joinStatements.append("""
            inner join \(connectedTableName) as \(alias)
              on \(connectedColumn) = \(foreignKeyName)
            """)
        }

        return """
        select
          \(joinedAsSelectedColumns(columns))
        from \(tableName) as root
        \(joinStatements.joined(separator: "\n"))
        """
    }

}

// MARK: - Private Helpers

/// Helper function that can be used as a shortcut to access the user's document
/// directory on the underlying OS. This is used to create the SQLite database file.
///
/// - Returns: the path to the user document directory.
private func getDocumentPath() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

/// Join a list of table columns joined and formatted for readability.
///
/// - Parameter columns the list of column names
/// - Parameter perLine max numbers of columns per line
/// - Returns: a list of columns that can be used in `select` SQL statements
internal func joinedAsSelectedColumns(_ columns: [String], perLine: Int = 3) -> String {
    return columns.enumerated().reduce("") { partial, entry in
        let spacer = entry.offset == 0 || entry.offset % perLine == 0 ? "\n  " : " "
        let isFirstOrLast = entry.offset == 0 || entry.offset >= columns.count
        let separator = isFirstOrLast ? "" : ",\(spacer)"
        return partial + separator + entry.element
    }
}
