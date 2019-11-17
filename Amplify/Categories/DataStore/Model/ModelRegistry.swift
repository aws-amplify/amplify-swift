//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ModelRegistry {
    public typealias ModelDecoder = (String) throws -> Model

    private static var modelTypes = [String: Model.Type]()

    private static var decoders = [String: ModelDecoder]()

    public static var models: [Model.Type] {
        Array(modelTypes.values)
    }

    public static func register<M: Model>(modelType: M.Type) {

        let decoder: ModelDecoder = { jsonString in
            let decoder = JSONDecoder()
            guard let data = jsonString.data(using: .utf8) else {
                throw DataStoreError.decodingError(
                    "Unable to get data from mutation event",
                    """
                    Validate that the json string contains no invalid UTF8 data:

                    \(jsonString)
                    """)
            }

            let model = try decoder.decode(modelType, from: data)
            return model
        }

        decoders[modelType.modelName] = decoder
        modelTypes[modelType.modelName] = modelType
    }

    public static func modelType(from name: String) -> Model.Type? {
        modelTypes[name]
    }

    public static func decode(modelName: String, from jsonString: String) throws -> Model {
        guard let decoder = decoders[modelName] else {
            throw DataStoreError.decodingError(
                "No decoder found for model named \(modelName)",
                """
                There is no decoder registered for the model named \(modelName). \
                Register models with `ModelRegistry.register(modelName:)` at startup.
                """)
        }

        return try decoder(jsonString)
    }
}

extension ModelRegistry {
    static func reset() {
        modelTypes = [:]
        decoders = [:]
    }
}
