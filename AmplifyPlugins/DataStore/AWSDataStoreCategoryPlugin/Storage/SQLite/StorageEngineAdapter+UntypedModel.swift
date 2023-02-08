//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SQLite

extension SQLiteStorageEngineAdapter {

    func save(untypedModel: Model, completion: DataStoreCallback<Model>) {
        guard let connection = connection else {
            completion(.failure(.nilSQLiteConnection()))
            return
        }

        do {
            let modelName: ModelName
            if let jsonModel = untypedModel as? JSONValueHolder,
               let modelNameFromJson = jsonModel.jsonValue(for: "__typename") as? String {
                modelName = modelNameFromJson
            } else {
                modelName = untypedModel.modelName
            }

            guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
                let error = DataStoreError.invalidModelName(modelName)
                throw error
            }

            let shouldUpdate = try exists(modelSchema,
                                          withIdentifier: untypedModel.identifier(schema: modelSchema))

            // swiftlint:disable:next todo
            // TODO serialize result and create a new instance of the model
            // (some columns might be auto-generated after DB insert/update)
            if shouldUpdate {
                let statement = UpdateStatement(model: untypedModel, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            } else {
                let statement = InsertStatement(model: untypedModel, modelSchema: modelSchema)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            completion(.success(untypedModel))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate? = nil,
               completion: DataStoreCallback<[Model]>) {
        guard let connection = connection else {
            completion(.failure(.nilSQLiteConnection()))
            return
        }
        do {
            let statement = SelectStatement(from: modelSchema, predicate: predicate)
            let rows = try connection.prepare(statement.stringValue).run(statement.variables)
            let result: [Model] = try rows.convertToUntypedModel(using: modelSchema, statement: statement)
            completion(.success(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

}
