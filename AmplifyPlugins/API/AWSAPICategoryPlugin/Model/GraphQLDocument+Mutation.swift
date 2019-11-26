//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public struct GraphQLMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let model: Model
    public let modelType: Model.Type
    public let mutationType: GraphQLMutationType
    public let variables: [String: Any]

    public init(of model: Model, type mutationType: GraphQLMutationType) {
        self.model = model
        self.modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.mutationType = mutationType
        if mutationType == .delete {
            self.variables = [
                "input": [
                    "id": model.id
                ]
            ]
        } else {
            self.variables = [
                "input": model.graphQLInput
            ]
        }
    }

    public var name: String {
        mutationType.rawValue + model.schema.graphQLName
    }

    public var decodePath: String {
        name
    }

    public var stringValue: String {
        let mutationName = name.toPascalCase()
        let inputName = "input"
        let inputType = "\(mutationName)Input!"

        let schema = model.schema
        var fields = schema.graphQLFields.map { $0.graphQLName }

        // All mutation documents should include typename in the selection set,
        // to support type-erased operations on the client
        fields.append("__typename")

        let document = """
        \(documentType) \(mutationName)($\(inputName): \(inputType)) {
          \(name)(\(inputName): $\(inputName)) {
            \(fields.joined(separator: "\n    "))
          }
        }
        """

        return document
    }

}
