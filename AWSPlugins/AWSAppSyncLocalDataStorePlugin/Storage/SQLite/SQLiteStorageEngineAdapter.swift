//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Helper function that can be used as a shortcut to access the user's document
/// directory on the underlying OS.
private func getDocumentPath() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

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
        pragma encoding = "UTF-8";
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

            var result: [M] = []
            for row in rows {
                var values: [String: Any] = [:]
                for (index, property) in M.properties.enumerated() {
                    // TODO is it safe to rely on key order?
                    // is there a name -> value map in the result set?
                    let binding: Binding? = index < row.count ? row[index] : nil
                    values[property.metadata.name] = property.value(from: binding)
                }
                let model = try modelType.from(dictionary: values)
                result.append(model)
            }
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
            statement += "  \(metadata.sqlName) \(metadata.sqlType.rawValue)"
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
            statement += "  foreign key(\(foreignKey.metadata.sqlName)) "
            guard let connectedModel = foreignKey.metadata.connectedModel else {
                preconditionFailure(
                    """
                    Model properties that are foreign keys must be connected to another Model.
                    Check the "ModelProperty" section of your "\(name)+Metadata.swift" file.
                    """
                )
            }

            let connectedId = connectedModel.properties.first { $0.metadata.isPrimaryKey }!
            statement += "references \(connectedModel.name)(\(connectedId.metadata.sqlName))"
        }

        statement += "\n);"
        return statement
    }

    internal func getInsertStatement(for modelType: PersistentModel.Type) -> String {
        let properties = modelType.properties.columns()
        let columns = properties.map { $0.metadata.sqlName }
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
        let columns = properties.map { $0.metadata.sqlName }
        return "select \(columns.joined(separator: ", ")) from \(modelType.name)"
    }

}
