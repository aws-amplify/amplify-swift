//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A convenience implementation of `GraphQLDocument` that represents a delete operation, requiring no model data
public class GraphQLDeleteSyncMutation: GraphQLDocument {
    public let documentType = GraphQLDocumentType.mutation
    public let mutationType = GraphQLMutationType.delete

    public let modelName: String
    public let modelType: Model.Type
    public let id: Model.Identifier
    public let version: Int?

    public init(of modelName: String, id: Model.Identifier, version: Int?) throws {
        self.modelName = modelName
        self.id = id
        self.version = version

        guard let modelType = ModelRegistry.modelType(from: modelName) else {
            throw DataStoreError.invalidModelName(modelName)
        }
        self.modelType = modelType
    }

    public var name: String {
        mutationType.rawValue + modelName
    }

    public var decodePath: String {
        name
    }

    public var hasSyncableModels: Bool {
        true
    }

    public var stringValue: String {
        let mutationName = name.pascalCased()
        let inputName = "input"
        let inputType = "\(mutationName)Input!"

        let document = """
        \(documentType) \(mutationName)($\(inputName): \(inputType)) {
          \(name)(\(inputName): $\(inputName)) {
            \(selectionSetFields.joined(separator: "\n    "))
          }
        }
        """

        return document
    }

    public var variables: [String: Any] {
        var graphQLInput = ["id": id] as [String: Any?]
        if let version = version {
            graphQLInput.updateValue(version, forKey: "_version")
        }

        return [
            "input": graphQLInput
        ]
    }
}
