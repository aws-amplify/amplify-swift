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

        do {
            let connection = try Connection(path)
            self.init(connection: connection)
        } catch {
            throw DataStoreError.invalidDatabase(path: path, error)
        }
    }

    internal init(connection: Connection) {
        self.connection = connection
    }

    public func setUp(models: [Model.Type]) throws {
        let createTableStatements = models
            .sortByDependencyOrder()
            .map { CreateTableStatement(modelType: $0).stringValue }
            .joined(separator: "\n")

        // database setup statement
        let statement = """
        pragma auto_vacuum = full;
        pragma encoding = "utf-8";
        pragma foreign_keys = on;
        pragma case_sensitive_like = off;
        \(createTableStatements)
        """

        do {
            try connection.execute(statement)
        } catch {
            throw DataStoreError.invalidOperation(causedBy: error)
        }
    }

    public func save<M: Model>(_ model: M, completion: DataStoreCallback<M>) {
        do {
            let modelType = type(of: model)
            let shouldUpdate = try exists(modelType, withId: model.id)

            if shouldUpdate {
                let statement = UpdateStatement(model: model)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            } else {
                let statement = InsertStatement(model: model)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            // load the recent saved instance and pass it back to the callback
            query(modelType, predicate: field("id").eq(model.id)) {
                switch $0 {
                case .success(let result):
                    if let saved = result.first {
                        completion(.success(saved))
                    } else {
                        completion(.failure(.nonUniqueResult(model: modelType.modelName,
                                                             count: result.count)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: Model.Identifier,
                                 completion: (DataStoreResult<Void>) -> Void) {
        do {
            let statement = DeleteStatement(modelType: modelType, withId: id)
            _ = try connection.prepare(statement.stringValue).run(statement.variables)
            completion(.emptyResult)
        } catch {
            completion(.failure(causedBy: error))
        }

    }

    public func query<M: Model>(_ modelType: M.Type,
                                predicate: QueryPredicate? = nil,
                                completion: DataStoreCallback<[M]>) {
        do {
            let statement = SelectStatement(from: modelType, predicate: predicate)
            let rows = try connection.prepare(statement.stringValue).run(statement.variables)
            let result: [M] = try rows.convert(to: modelType)
            completion(.success(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    public func exists(_ modelType: Model.Type, withId id: Model.Identifier) throws -> Bool {
        let schema = modelType.schema
        let primaryKey = schema.primaryKey.sqlName
        let sql = "select count(\(primaryKey)) from \(schema.name) where \(primaryKey) = ?"

        let result = try connection.scalar(sql, [id])
        if let count = result as? Int64 {
            if count > 1 {
                throw DataStoreError.nonUniqueResult(model: modelType.modelName,
                                                     count: Int(count))
            }
            return count == 1
        }
        return false
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
