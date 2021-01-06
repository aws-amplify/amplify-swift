//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import SQLite

extension Statement {
    func convert(toUntypedModel modelType: Model.Type,
                 using statement: SelectStatement) throws -> [Model] {
        var models = [Model]()

        for row in self {
            let modelValues = try convert(row: row, to: modelType, using: statement)
            let untypedModel = try convert(toAnyModel: modelType, modelDictionary: modelValues)
            models.append(untypedModel)
        }

        return models
    }

    private func convert(toAnyModel modelType: Model.Type, modelDictionary: ModelValues) throws -> Model {
        let data = try JSONSerialization.data(withJSONObject: modelDictionary)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            let error = DataStoreError.decodingError(
                "Could not create JSON string from model data",
                """
                The values below could not be serialized into a String. Ensure the data below contains no invalid UTF8:
                \(modelDictionary)
                """
            )
            throw error
        }

        let instance = try ModelRegistry.decode(modelName: modelType.modelName, from: jsonString)
        return instance
    }
}
