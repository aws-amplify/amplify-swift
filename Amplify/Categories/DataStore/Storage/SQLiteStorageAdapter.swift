//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

func getDocumentPath() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

final public class SQLiteStorageAdapter: StorageAdapter {

    internal var connection: Connection!

    public convenience init(databaseName: String = "database") throws {
        guard let documentsPath = getDocumentPath() else {
            throw DataStoreError.invalidDatabase
        }
        let path = documentsPath
            .appendingPathComponent("amplify-datastore", isDirectory: true)
            .appendingPathComponent("\(databaseName).db")
            .absoluteString
        let connection = try Connection(path)
        self.init(connection: connection)
    }

    internal init(connection: Connection) {
        self.connection = connection
    }

    public func setUp(models: [PersistentModel.Type]) throws {
        let createTableStatements = models.map { model in
            getCreateTableStatement(for: model)
        }.joined(separator: "\n")

        // database setup statement
        let statement = """
        pragma auto_vacuum = full;
        pragma encoding = "UTF-8";
        \(createTableStatements)
        """
        try connection.execute(statement)
        // wrap error?
    }

    public func save(_ model: PersistentModel) throws {
        let modelType = type(of: model)
        let statement = getInsertStatement(for: modelType)
        let values = model.sqlValues(for: modelType.properties.columns())
        try connection.prepare(statement).run(values)
        // TODO handle result
    }

    public func select<M: PersistentModel>(from model: M.Type) throws -> [M] {
        let statement = getSelectStatement(for: model)
        let rows = try connection.prepare(statement)

        var result: [M] = []
        for row in rows {
            var values: [String: Any?] = [:]
            for (index, property) in M.properties.enumerated() {
                // TODO is it safe to rely on key order?
                // is there a name -> value map in the result set?
                let binding: Binding? = index < row.count ? row[index] : nil
                values[property.metadata.name] = property.value(from: binding)
            }
            let model = try model.from(dictionary: values)
            result.append(model)
        }
        return result
    }

    // MARK: - Internal

    internal func getCreateTableStatement(for model: PersistentModel.Type) -> String {
        var statement = "create table if not exists \(model.name) (\n"

        let properties = model.properties.columns()
        let foreignKeys = model.properties.foreignKeys()

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
                // TODO: throw error
                return ""
            }

            let connectedId = connectedModel.properties.first { $0.metadata.isPrimaryKey }!
            statement += "references \(connectedModel.name)(\(connectedId.metadata.sqlName))"
        }

        statement += "\n);"
        return statement
    }

    internal func getInsertStatement(for model: PersistentModel.Type) -> String {
        let properties = model.properties.columns()
        let columns = properties.map { $0.metadata.sqlName }
        var statement = "insert into \(model.name) "
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

    internal func getSelectStatement(for model: PersistentModel.Type) -> String {
        let properties = model.properties.columns()
        let columns = properties.map { $0.metadata.sqlName }
        return "select \(columns.joined(separator: ", ")) from \(model.name)"
    }

}
