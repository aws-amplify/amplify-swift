//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with the value of `Model.Identifier` for a "delete" mutation or "get" query.
public struct ModelIdDecorator: ModelBasedGraphQLDocumentDecorator {

    private let input: ModelDecoratorInput

    public enum ModelDecoratorInput {
        case delete(Model)
        case query(Model.Identifier, fields: [String: String]? = nil)
    }

    public init(_ input: ModelDecoratorInput) {
        self.input = input
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .delete(let model) = input {
            var objectMap = [String: Any?]()
            if let customPrimaryKeys = modelSchema.customPrimaryIndexFields {
                for key in customPrimaryKeys {
                    objectMap[key] = model[key]
                }
            } else {
                objectMap["id"] = model.id
            }

            inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                   value: .object(objectMap))
        } else if case .query(let id, let fields) = input {
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .scalar(id))

            if let fields = fields {
                for (fieldName, value) in fields {
                    inputs[fieldName] = GraphQLDocumentInput(type: "String!", value: .scalar(value))
                }
            }
        }

        return document.copy(inputs: inputs)
    }
}
