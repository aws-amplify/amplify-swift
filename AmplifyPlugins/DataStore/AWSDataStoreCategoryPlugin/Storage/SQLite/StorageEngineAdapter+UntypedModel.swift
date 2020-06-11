//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SQLite

extension SQLiteStorageEngineAdapter {

    func save(untypedModel: Model, completion: DataStoreCallback<Model>) {
        do {
            guard let modelType = ModelRegistry.modelType(from: untypedModel.modelName) else {
                let error = DataStoreError.invalidModelName(untypedModel.modelName)
                throw error
            }

            let shouldUpdate = try exists(modelType, withId: untypedModel.id)

            // TODO serialize result and create a new instance of the model
            // (some columns might be auto-generated after DB insert/update)
            if shouldUpdate {
                let statement = UpdateStatement(model: untypedModel)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            } else {
                let statement = InsertStatement(model: untypedModel)
                _ = try connection.prepare(statement.stringValue).run(statement.variables)
            }

            completion(.success(untypedModel))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate? = nil,
               completion: DataStoreCallback<[Model]>) {
        do {
            let statement = SelectStatement(from: modelType, predicate: predicate)
            let rows = try connection.prepare(statement.stringValue).run(statement.variables)
            let result: [Model] = try rows.convert(toUntypedModel: modelType, using: statement)
            completion(.success(result))
        } catch {
            completion(.failure(causedBy: error))
        }
    }

}
