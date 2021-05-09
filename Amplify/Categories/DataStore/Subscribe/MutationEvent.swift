//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct MutationEvent: Model {

    /// <#Description#>
    public let id: Identifier

    /// <#Description#>
    public let modelId: Identifier

    /// <#Description#>
    public var modelName: String

    /// <#Description#>
    public var json: String

    /// <#Description#>
    public var mutationType: String

    /// <#Description#>
    public var createdAt: Temporal.DateTime

    /// <#Description#>
    public var version: Int?

    /// <#Description#>
    public var inProcess: Bool

    /// <#Description#>
    public var graphQLFilterJSON: String?

    /// <#Description#>
    /// - Parameters:
    ///   - id: <#id description#>
    ///   - modelId: <#modelId description#>
    ///   - modelName: <#modelName description#>
    ///   - json: <#json description#>
    ///   - mutationType: <#mutationType description#>
    ///   - createdAt: <#createdAt description#>
    ///   - version: <#version description#>
    ///   - inProcess: <#inProcess description#>
    ///   - graphQLFilterJSON: <#graphQLFilterJSON description#>
    public init(id: Identifier = UUID().uuidString,
                modelId: String,
                modelName: String,
                json: String,
                mutationType: MutationType,
                createdAt: Temporal.DateTime = .now(),
                version: Int? = nil,
                inProcess: Bool = false,
                graphQLFilterJSON: String? = nil) {
        self.id = id
        self.modelId = modelId
        self.modelName = modelName
        self.json = json
        self.mutationType = mutationType.rawValue
        self.createdAt = createdAt
        self.version = version
        self.inProcess = inProcess
        self.graphQLFilterJSON = graphQLFilterJSON
    }

    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - modelSchema: <#modelSchema description#>
    ///   - mutationType: <#mutationType description#>
    ///   - version: <#version description#>
    ///   - graphQLFilterJSON: <#graphQLFilterJSON description#>
    /// - Throws: <#description#>
    public init<M: Model>(model: M,
                          modelSchema: ModelSchema,
                          mutationType: MutationType,
                          version: Int? = nil,
                          graphQLFilterJSON: String? = nil) throws {
        let json = try model.toJSON()
        self.init(modelId: model.id,
                  modelName: modelSchema.name,
                  json: json,
                  mutationType: mutationType,
                  version: version,
                  graphQLFilterJSON: graphQLFilterJSON)

    }

    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - mutationType: <#mutationType description#>
    ///   - version: <#version description#>
    ///   - graphQLFilterJSON: <#graphQLFilterJSON description#>
    /// - Throws: <#description#>
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

    /// <#Description#>
    /// - Throws: <#description#>
    /// - Returns: <#description#>
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
