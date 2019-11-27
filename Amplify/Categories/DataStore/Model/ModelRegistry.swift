//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ModelRegistry {

    /// ModelDecoders are used to decode untyped model data, looking up by model name
    private typealias ModelDecoder = (String, JSONDecoder) throws -> Model

    private static var modelTypes = [String: Model.Type]()

    private static var modelDecoders = [String: ModelDecoder]()

    public static var models: [Model.Type] {
        Array(modelTypes.values)
    }

    public static func register<M: Model>(modelType: M.Type) {
        let modelDecoder: ModelDecoder = { jsonString, jsonDecoder in
            let model = try modelType.from(json: jsonString, decoder: jsonDecoder)
            return model
        }

        modelDecoders[modelType.modelName] = modelDecoder

        modelTypes[modelType.modelName] = modelType
    }

    public static func modelType(from name: String) -> Model.Type? {
        modelTypes[name]
    }

    public static func decode(modelName: String,
                              from jsonString: String,
                              jsonDecoder: JSONDecoder = JSONDecoder()) throws -> Model {
        guard let decoder = modelDecoders[modelName] else {
            throw DataStoreError.decodingError(
                "No decoder found for model named \(modelName)",
                """
                There is no decoder registered for the model named \(modelName). \
                Register models with `ModelRegistry.register(modelName:)` at startup.
                """)
        }

        return try decoder(jsonString, jsonDecoder)
    }
}

extension ModelRegistry {
    static func reset() {
        modelTypes = [:]
        modelDecoders = [:]
    }
}
