//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension GraphQLMutation {
    convenience init(of anyModel: AnyModel, type mutationType: GraphQLMutationType) {
        self.init(of: anyModel.instance, type: mutationType)
    }
}

/// A concrete implementation of `GraphQLDocument` that represents a data mutation operation.
/// The type of the operation is defined by `GraphQLMutationType`.
public class GraphQLMutation: GraphQLDocument {

    public let documentType = GraphQLDocumentType.mutation
    public let model: Model
    public let modelType: Model.Type
    public let mutationType: GraphQLMutationType

    public init(of model: Model,
                type mutationType: GraphQLMutationType) {
        self.model = model
        self.modelType = ModelRegistry.modelType(from: model.modelName) ?? Swift.type(of: model)
        self.mutationType = mutationType
    }

    public var name: String {
        mutationType.rawValue + model.schema.graphQLName
    }

    public var decodePath: String {
        name
    }

    public var hasSyncableModels: Bool {
        false
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
        if mutationType == .delete {
            return [
                "input": [
                    "id": model.id
                ]
            ]
        } else {
            return [
                "input": model.graphQLInput
            ]
        }
    }
}
