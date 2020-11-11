//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite
import AWSPluginsCore

/// [SQLite](https://sqlite.org) `StorageEngineAdapter` implementation. This class provides
/// an integration layer between the AppSyncLocal `StorageEngine` and SQLite for local storage.
final class SQLiteStorageEngineAdapter: StorageEngineAdapter {

    internal var connection: Connection!
    private var dbFilePath: URL?
    static let dbVersionKey = "com.amazonaws.DataStore.dbVersion"

    convenience init(version: String,
                     databaseName: String = "database",
                     userDefaults: UserDefaults = UserDefaults.standard) throws {
        var dbFilePath = SQLiteStorageEngineAdapter.getDbFilePath(databaseName: databaseName)
        try SQLiteStorageEngineAdapter.clearIfNewVersion(version: version, dbFilePath: dbFilePath)

        let path = dbFilePath.absoluteString

        let connection: Connection
        do {
            connection = try Connection(path)

            var urlResourceValues = URLResourceValues()
            urlResourceValues.isExcludedFromBackup = true
            try dbFilePath.setResourceValues(urlResourceValues)
        } catch {
            throw DataStoreError.invalidDatabase(path: path, error)
        }

        try self.init(connection: connection,
                      dbFilePath: dbFilePath,
                      userDefaults: userDefaults,
                      version: version)

    }

    internal init(connection: Connection,
                  dbFilePath: URL? = nil,
                  userDefaults: UserDefaults = UserDefaults.standard,
                  version: String = "version") throws {
        self.connection = connection
        self.dbFilePath = dbFilePath
        try SQLiteStorageEngineAdapter.initializeDatabase(connection: connection)
        log.verbose("Initialized \(connection)")
        userDefaults.set(version, forKey: SQLiteStorageEngineAdapter.dbVersionKey)
    }

    static func initializeDatabase(connection: Connection) throws {
        log.debug("Initializing database connection: \(String(describing: connection))")

        if log.logLevel >= .verbose {
            connection.trace { self.log.verbose($0) }
        }

        let databaseInitializationStatement = """
        pragma auto_vacuum = full;
        pragma encoding = "utf-8";
        pragma foreign_keys = on;
        pragma case_sensitive_like = off;
        """

        try connection.execute(databaseInitializationStatement)
    }

    static func getDbFilePath(databaseName: String) -> URL {
        guard let documentsPath = getDocumentPath() else {
            preconditionFailure("Could not create the database. The `.documentDirectory` is invalid")
        }
        return documentsPath.appendingPathComponent("\(databaseName).db")
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
        log.debug("Setting up \(modelSchemas.count) models")

        let createTableStatements = modelSchemas
            .sortByDependencyOrder()
            .map { CreateTableStatement(modelSchema: $0).stringValue }
            .joined(separator: "\n")

        do {
            try connection.execute(createTableStatements)
        } catch {
            throw DataStoreError.invalidOperation(causedBy: error)
        }
    }

    func save<M: Model>(_ model: M, condition: QueryPredicate? = nil, completion: @escaping DataStoreCallback<M>) {
         save(model, modelSchema: model.schema, condition: condition, completion: completion)
     }

    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition: QueryPredicate? = nil,
                        completion: DataStoreCallback<M>) {
        do {
            let modelType = type(of: model)
            let modelExists = try exists(modelSchema, withId: model.id)

            if !modelExists {
                if condition != nil {
                    let dataStoreError = DataStoreError.invalidCondition(
                        "Cannot apply a condition on model which does not exist.",
                        "Save the model instance without a condition first.")
                    completion(.failure(causedBy: dataStoreError))
                    return
                }

                let statement = InsertStatement(model: model, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            if modelExists {
                if condition != nil {
                    let modelExistsWithCondition = try exists(modelSchema, withId: model.id, predicate: condition)
                    if !modelExistsWithCondition {
                        let dataStoreError = DataStoreError.invalidCondition(
                        "Save failed due to condition did not match existing model instance.",
                        "The save will continue to fail until the model instance is updated.")
                        completion(.failure(causedBy: dataStoreError))

                        return
                    }
                }

                let statement = UpdateStatement(model: model,
                                                modelSchema: modelSchema,
                                                condition: condition)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            // load the recent saved instance and pass it back to the callback
            query(modelType, modelSchema: modelSchema, predicate: field("id").eq(model.id)) {
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

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          predicate: QueryPredicate,
                          completion: (DataStoreResult<[M]>) -> Void) {
        do {
            let statement = DeleteStatement(modelSchema: modelSchema, predicate: predicate)
            _ = try connection.prepare(statement.stringValue).run(statement.variables)
            completion(.success([]))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          completion: (DataStoreResult<M?>) -> Void) {
        delete(untypedModelType: modelType, modelSchema: modelSchema, withId: id) { result in
            switch result {
            case .success:
                completion(.success(nil))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: Model.Identifier,
                completion: DataStoreCallback<Void>) {
        do {
            let statement = DeleteStatement(modelSchema: modelSchema, withId: id)
            _ = try connection.prepare(statement.stringValue).run(statement.variables)
            completion(.emptyResult)
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate? = nil,
                         sort: [QuerySortDescriptor]? = nil,
                         paginationInput: QueryPaginationInput? = nil,
                         completion: DataStoreCallback<[M]>) {
        query(modelType,
              modelSchema: modelType.schema,
              predicate: predicate,
              sort: sort,
              paginationInput: paginationInput,
              completion: completion)
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate? = nil,
                         sort: [QuerySortDescriptor]? = nil,
                         paginationInput: QueryPaginationInput? = nil,
                         completion: DataStoreCallback<[M]>) {
        do {
            let statement = SelectStatement(from: modelSchema,
                                            predicate: predicate,
                                            sort: sort,
                                            paginationInput: paginationInput)
            let rows = try connection.prepare(statement.stringValue).run(statement.variables)
            let result: [M] = try rows.convert(to: modelType, using: statement)
            completion(.success(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func exists(_ modelSchema: ModelSchema,
                withId id: Model.Identifier,
                predicate: QueryPredicate? = nil) throws -> Bool {
        let primaryKey = modelSchema.primaryKey.sqlName
        var sql = "select count(\(primaryKey)) from \(modelSchema.name) where \(primaryKey) = ?"
        var variables: [Binding?] = [id]
        if let predicate = predicate {
            let conditionStatement = ConditionStatement(modelSchema: modelSchema, predicate: predicate)
            sql = """
            \(sql)
            \(conditionStatement.stringValue)
            """

            variables.append(contentsOf: conditionStatement.variables)
        }

        let result = try connection.scalar(sql, variables)
        if let count = result as? Int64 {
            if count > 1 {
                throw DataStoreError.nonUniqueResult(model: modelSchema.name, count: Int(count))
            }
            return count == 1
        }
        return false
    }

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>? {
        let model = anyModel.instance
        let results = try queryMutationSync(for: [model])
        return results.first
    }

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>] {
        let statement = SelectStatement(from: MutationSyncMetadata.schema)
        let primaryKey = MutationSyncMetadata.schema.primaryKey.sqlName
        // This is a temp workaround since we don't currently support the "in" operator
        // in query predicates (this avoids the 1 + n query problem). Consider adding "in" support
        let placeholders = Array(repeating: "?", count: models.count).joined(separator: ", ")
        let sql = statement.stringValue + "\nwhere \(primaryKey) in (\(placeholders))"

        // group models by id for fast access when creating the tuple
        let modelById = Dictionary(grouping: models, by: { $0.id }).mapValues { $0.first! }
        let ids = [String](modelById.keys)
        let rows = try connection.prepare(sql).bind(ids)

        let syncMetadataList = try rows.convert(to: MutationSyncMetadata.self,
                                                using: statement)
        let mutationSyncList = try syncMetadataList.map { syncMetadata -> MutationSync<AnyModel> in
            guard let model = modelById[syncMetadata.id] else {
                throw DataStoreError.invalidOperation(causedBy: nil)
            }
            let anyModel = try model.eraseToAnyModel()
            return MutationSync<AnyModel>(model: anyModel, syncMetadata: syncMetadata)
        }
        return mutationSyncList
    }

    func queryMutationSyncMetadata(for modelId: Model.Identifier) throws -> MutationSyncMetadata? {
        let modelType = MutationSyncMetadata.self
        let statement = SelectStatement(from: modelType.schema, predicate: field("id").eq(modelId))
        let rows = try connection.prepare(statement.stringValue).run(statement.variables)
        let result = try rows.convert(to: modelType,
                                      using: statement)
        return try result.unique()
    }

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata? {
        let statement = SelectStatement(from: ModelSyncMetadata.schema,
                                        predicate: field("id").eq(modelSchema.name))
        let rows = try connection.prepare(statement.stringValue).run(statement.variables)
        let result = try rows.convert(to: ModelSyncMetadata.self,
                                      using: statement)
        return try result.unique()
    }

    func transaction(_ transactionBlock: BasicThrowableClosure) throws {
        try connection.transaction {
            try transactionBlock()
        }
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        guard let dbFilePath = dbFilePath else {
            log.error("Attempt to clear DB, but file path was empty")
            completion(.failure(causedBy: DataStoreError.invalidDatabase(path: "Database path not set", nil)))
            return
        }
        connection = nil
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: dbFilePath)
        } catch {
            log.error("Failed to delete database file located at: \(dbFilePath), error: \(error)")
            completion(.failure(causedBy: DataStoreError.invalidDatabase(path: dbFilePath.absoluteString, error)))
        }
        completion(.successfulVoid)
    }

    static func clearIfNewVersion(version: String,
                                  dbFilePath: URL,
                                  userDefaults: UserDefaults = UserDefaults.standard,
                                  fileManager: FileManager = FileManager.default) throws {

        guard let previousVersion = userDefaults.string(forKey: dbVersionKey) else {
            return
        }

        if previousVersion == version {
            return
        }

        guard fileManager.fileExists(atPath: dbFilePath.path) else {
            return
        }

        log.verbose("\(#function) Warning: Schema change detected, removing your previous database")
        do {
            try fileManager.removeItem(at: dbFilePath)
        } catch {
            log.error("\(#function) Failed to delete database file located at: \(dbFilePath), error: \(error)")
            throw DataStoreError.invalidDatabase(path: dbFilePath.path, error)
        }
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

extension SQLiteStorageEngineAdapter: DefaultLogger { }
