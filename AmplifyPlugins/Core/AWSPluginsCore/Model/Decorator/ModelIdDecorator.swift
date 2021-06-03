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

    private let id: Model.Identifier
    private let fields: [String: String]?

    public init(model: Model) {
        var fields = [String: String]()
        if let customPrimaryKeys = model.schema.customPrimaryIndexFields {
            for key in customPrimaryKeys {
                fields[key] = model[key] as? String
            }
        }
        self.init(id: model.id, fields: fields)
    }

    public init(id: Model.Identifier, fields: [String: String]? = nil) {
        self.id = id
        self.fields = fields
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .mutation = document.operationType {
            var objectMap = [String: String]()
            if let fields = fields {
                for (fieldName, value) in fields where fieldName != "id" {
                    objectMap[fieldName] = value
                }
            }
            objectMap["id"] = id
            inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                   value: .object(objectMap))
        } else if case .query = document.operationType {
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .scalar(id))

            if let fields = fields {
                for (fieldName, value) in fields where fieldName != "id" {
                    inputs[fieldName] = GraphQLDocumentInput(type: "String!", value: .scalar(value))
                }
            }
        }

        return document.copy(inputs: inputs)
    }
}
