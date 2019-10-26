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
        let path = documentsPath.appendingPathComponent("\(databaseName).db").absoluteString
        let connection = try Connection(path)
        self.init(connection: connection)
    }

    internal init(connection: Connection) {
        self.connection = connection
    }

    public func setUp(models: [Model.Type]) throws {
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

    public func save<M: Model>(_ model: M, completion: DataStoreCallback<M>) {
        let modelType = type(of: model)
        let sql = getInsertStatement(for: modelType)
        let values = model.sqlValues(for: modelType.schema.allFields.columns())

        do {
            _ = try connection.prepare(sql).run(values)
            // TODO serialize result and create a new instance of the model
            // (some columns might be auto-generated after DB insert/update)
            completion(.result(model))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    public func query<M: Model>(_ modelType: M.Type,
                                completion: DataStoreCallback<[M]>) {
        do {
            let statement = getSelectStatement(for: modelType)
            let queryStart = CFAbsoluteTimeGetCurrent()
            let rows = try connection.prepare(statement).run()
            print("==> Query Done")
            print(CFAbsoluteTimeGetCurrent() - queryStart)
            let serializeStart = CFAbsoluteTimeGetCurrent()
            let result: [M] = try rows.convert(to: M.self)
            print("==> Serialize Done")
            print(CFAbsoluteTimeGetCurrent() - serializeStart)
            completion(.result(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    // MARK: - Internal

    internal func getCreateTableStatement(for modelType: Model.Type) -> String {
        let schema = modelType.schema
        let name = schema.name
        var statement = "create table if not exists \(name) (\n"

        let columns = schema.allFields.columns()
        let foreignKeys = schema.allFields.foreignKeys()

        for (index, column) in columns.enumerated() {
            statement += "  \"\(column.sqlName)\" \(column.sqlType.rawValue)"
            if column.isPrimaryKey {
                statement += " primary key"
            }
            if column.isRequired {
                statement += " not null"
            }

            if index < columns.endIndex - 1 || !foreignKeys.isEmpty {
                statement += ",\n"
            }
        }

        for foreignKey in foreignKeys {
            statement += "  foreign key(\"\(foreignKey.sqlName)\") "
            guard let connectedModel = foreignKey.connectedModel else {
                preconditionFailure("""
                Model fields that are foreign keys must be connected to another Model.
                Check the `ModelSchema` section of your "\(name)+Schema.swift" file.
                """)
            }

            let connectedId = connectedModel.schema.primaryKey
            statement += "references \(connectedModel.schema.name)(\"\(connectedId.sqlName)\")"
        }

        statement += "\n);"
        return statement
    }

    internal func getInsertStatement(for modelType: Model.Type) -> String {
        let schema = modelType.schema
        let fields = schema.allFields.columns()
        let columns = fields.map { $0.columnName() }
        var statement = "insert into \(schema.name) "
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

    internal func getSelectStatement(for modelType: Model.Type) -> String {
        let schema = modelType.schema
        let fields = schema.allFields.columns()
        let tableName = schema.name
        var columns = fields.map { field -> String in
            return field.columnName(forNamespace: "root") + " " + field.columnAlias()
        }

        // eager load many-to-one relationships (simple inner join)
        var joinStatements: [String] = []
        for foreignKey in schema.allFields.foreignKeys() {
            let connectedModelType = foreignKey.connectedModel!
            let connectedSchema = connectedModelType.schema
            let connectedTableName = connectedModelType.schema.name

            // columns
            let alias = foreignKey.name
            let connectedColumn = connectedSchema.primaryKey.columnName(forNamespace: alias)
            let foreignKeyName = foreignKey.columnName(forNamespace: "root")

            // append columns from relationships
            columns += connectedSchema.allFields.columns().map { field -> String in
                return field.columnName(forNamespace: alias) + " " + field.columnAlias(forNamespace: alias)
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
