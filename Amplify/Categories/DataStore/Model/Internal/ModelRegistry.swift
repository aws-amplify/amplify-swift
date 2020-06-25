//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public struct ModelRegistry {
    private static let concurrencyQueue = DispatchQueue(label: "com.amazonaws.ModelRegistry.concurrency",
                                                        target: DispatchQueue.global())

    /// ModelDecoders are used to decode untyped model data, looking up by model name
    private typealias ModelDecoder = (String, JSONDecoder?) throws -> Model

    private static var modelTypes = [String: Model.Type]()

    private static var modelDecoders = [String: ModelDecoder]()

    public static var models: [Model.Type] {
        concurrencyQueue.sync {
            Array(modelTypes.values)
        }
    }

    public static func register(modelType: Model.Type) {
        concurrencyQueue.sync {
            let modelDecoder: ModelDecoder = { jsonString, jsonDecoder in
                let model = try modelType.from(json: jsonString, decoder: jsonDecoder)
                return model
            }

            modelDecoders[modelType.modelName] = modelDecoder

            modelTypes[modelType.modelName] = modelType
        }
    }

    public static func modelType(from name: String) -> Model.Type? {
        concurrencyQueue.sync {
            modelTypes[name]
        }
    }

    public static func decode(modelName: String,
                              from jsonString: String,
                              jsonDecoder: JSONDecoder? = nil) throws -> Model {
        try concurrencyQueue.sync {
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
}

extension ModelRegistry {
    static func reset() {
        concurrencyQueue.sync {
            modelTypes = [:]
            modelDecoders = [:]
        }
    }
}
