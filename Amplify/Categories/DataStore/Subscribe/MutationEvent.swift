//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct MutationEvent: Model {
    public typealias EventIdentifier = String
    public typealias ModelId = String

    public let id: EventIdentifier
    public let modelId: ModelId
    public var modelName: String
    public var json: String
    public var mutationType: String
    public var createdAt: Temporal.DateTime
    public var version: Int?
    public var inProcess: Bool
    public var graphQLFilterJSON: String?
    
    // MutationEvent, which is also the payload to DataStore.observe API is public and so we should make sure that
    // this is the right direction to go, since there's already a disparity across platforms on the observe API's
    // event type.
    public var changedFields: [String]?

    public init(id: EventIdentifier = UUID().uuidString,
                modelId: ModelId,
                modelName: String,
                json: String,
                mutationType: MutationType,
                createdAt: Temporal.DateTime = .now(),
                version: Int? = nil,
                inProcess: Bool = false,
                graphQLFilterJSON: String? = nil,
                changedFields: [String]? = nil) {
        self.id = id
        self.modelId = modelId
        self.modelName = modelName
        self.json = json
        self.mutationType = mutationType.rawValue
        self.createdAt = createdAt
        self.version = version
        self.inProcess = inProcess
        self.graphQLFilterJSON = graphQLFilterJSON
        self.changedFields = changedFields
    }

    public init<M: Model>(model: M,
                          modelSchema: ModelSchema,
                          mutationType: MutationType,
                          version: Int? = nil,
                          graphQLFilterJSON: String? = nil,
                          changedFields: [String]? = nil) throws {
        let json = try model.toJSON()
        self.init(modelId: model.identifier(schema: modelSchema).stringValue,
                  modelName: modelSchema.name,
                  json: json,
                  mutationType: mutationType,
                  version: version,
                  graphQLFilterJSON: graphQLFilterJSON,
                  changedFields: changedFields)

    }

    @available(*, deprecated, message: """
    Initializing from a model without a ModelSchema is deprecated.
    Use init(model:modelSchema:mutationType:version:graphQLFilterJSON:) instead.
    """)
    public init<M: Model>(model: M,
                          mutationType: MutationType,
                          version: Int? = nil,
                          graphQLFilterJSON: String? = nil) throws {
        try self.init(model: model,
                      modelSchema: model.schema,
                      mutationType: mutationType,
                      version: version,
                      graphQLFilterJSON: graphQLFilterJSON)

    }

    public func decodeModel() throws -> Model {
        let model = try ModelRegistry.decode(modelName: modelName, from: json)
        return model
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

extension MutationEvent: Sendable { }
