//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with the value of `ModelIdentifier` for a "delete" mutation or "get" query.
public struct ModelIdDecorator: ModelBasedGraphQLDocumentDecorator {
    /// Array of model fields and their stringified value
    private let identifierFields: [(name: String, value: String)]

    public init(model: Model, schema: ModelSchema) {
        self.identifierFields = model.identifier(schema: schema).fields.compactMap { fieldName, _ in
            guard let value = model.graphQLInputForPrimaryKey(modelFieldName: fieldName,
                                                              modelSchema: schema) else {
                      return nil
                  }

            return (name: fieldName, value: value)
        }
    }
    
    public init(identifiers: [String: String]) {
        self.identifierFields = identifiers.map { (name: $0.0, value: $0.1) }
    }

    @available(*, deprecated, message: "Use init(model:schema:)")
    public init(model: Model) {
        self.init(model: model, schema: model.schema)
    }

    @available(*, deprecated, message: "Use init(model:schema:)")
    public init(id: Model.Identifier, fields: [String: String]? = nil) {
        let identifier = (name: ModelIdentifierFormat.Default.name, value: id)
        var identifierFields = [identifier]

        if let fields = fields {
            identifierFields.append(contentsOf: fields.map { key, value in
                (name: key, value: value)
            })
        }
        self.identifierFields = identifierFields
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .mutation = document.operationType {
            var inputMap = [String: String]()
            for (name, value) in identifierFields {
                inputMap[name] = value
            }
            inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                   value: .object(inputMap))

        } else if case .query = document.operationType {
            for (name, value) in identifierFields {
                let graphQLInput = name == ModelIdentifierFormat.Default.name ?
                    GraphQLDocumentInput(type: "ID!", value: .scalar(value)) :
                    GraphQLDocumentInput(type: "String!", value: .scalar(value))
                inputs[name] = graphQLInput
            }
        }

        return document.copy(inputs: inputs)
    }
}
