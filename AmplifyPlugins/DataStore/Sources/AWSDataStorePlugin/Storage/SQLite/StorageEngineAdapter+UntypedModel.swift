//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SQLite

extension SQLiteStorageEngineAdapter {
    func save(_ model: Model, eagerLoad: Bool) -> Swift.Result<Model, DataStoreError> {
        let modelName: ModelName
        if let jsonModel = model as? JSONValueHolder,
           let modelNameFromJson = jsonModel.jsonValue(for: "__typename") as? String {
            modelName = modelNameFromJson
        } else {
            modelName = model.modelName
        }

        guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
            let error = DataStoreError.invalidModelName(modelName)
            return .failure(DataStoreError(error: error))
        }

        return exists(
            modelSchema,
            withIdentifier: model.identifier(schema: modelSchema),
            predicate: nil
        ).map { (modelExist) -> (any SQLStatement) in
           modelExist  ? UpdateStatement(model: model, modelSchema: modelSchema)
                       : InsertStatement(model: model, modelSchema: modelSchema)
       }
       .flatMap(executeSQLStatement(statement:))
       .flatMap { _ in
           query(
               modelSchema: modelSchema,
               predicate: model.identifier(schema: modelSchema).predicate,
               eagerLoad: eagerLoad
           )
       }
       .flatMap { models in
           if let model = models.first {
               return .success(model)
           } else {
               return .failure(.nonUniqueResult(model: modelName, count: models.count))
           }
       }
    }

    func query(
        modelSchema: ModelSchema,
        predicate: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<[Model], DataStoreError> {

        let statement = SelectStatement(
            from: modelSchema,
            predicate: predicate,
            eagerLoad: eagerLoad
        )

        return executeSQLStatement(statement: statement).tryMap {
            try $0.convertToUntypedModel(
                using: modelSchema,
                statement: statement,
                eagerLoad: eagerLoad
            )
        }

    }

}
