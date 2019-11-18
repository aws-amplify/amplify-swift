//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct MutationEvent: Model {
    public enum MutationType: String, Codable {
        case create
        case update
        case delete
    }

    public let id: Identifier
    public let modelName: String
    public let json: String
    public let mutationType: String
    public let createdAt: Date

    public init(id: Identifier = UUID().uuidString,
                modelName: String,
                data: String,
                mutationType: MutationType,
                createdAt: Date = Date()) {
        self.id = id
        self.modelName = modelName
        self.json = data
        self.mutationType = mutationType.rawValue
        self.createdAt = createdAt
    }

    public init<M: Model>(model: M,
                          mutationType: MutationType) throws {
        let modelType = type(of: model)
        let data = try model.toJSON()
        self.init(modelName: modelType.schema.name,
                  data: data,
                  mutationType: mutationType)
    }

    /// Decodes the model instance from the mutation event.
    public func decodeModel<M: Model>(as modelType: M.Type) throws -> M {
        let model = try ModelRegistry.decode(modelName: modelName, from: json)

        guard let typedModel = model as? M else {
            throw DataStoreError.decodingError(
                "Could not create '\(modelType.modelName)' from model",
                """
                Review the data in the JSON string below and ensure it doesn't contain invalid UTF8 data, and that \
                it is a valid \(modelType.modelName) instance:

                \(json)
                """)
        }

        return typedModel
    }
}
