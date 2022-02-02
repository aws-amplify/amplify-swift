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
                if let value = model.graphQLInputForPrimaryKey(modelFieldName: key) {
                    fields[key] = value
                }
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

extension Model {

    func graphQLInputForPrimaryKey(modelFieldName: ModelFieldName) -> String? {

        guard let modelField = schema.field(withName: modelFieldName) else {
            return nil
        }

        let fieldValueOptional = getFieldValue(for: modelField.name, modelSchema: schema)

        guard let fieldValue = fieldValueOptional else {
            return nil
        }

        // swiftlint:disable:next syntactic_sugar
        guard case .some(Optional<Any>.some(let value)) = fieldValue else {
            return nil
        }

        switch modelField.type {
        case .date, .dateTime, .time:
            if let date = value as? TemporalSpec {
                return date.iso8601String
            } else {
                return nil
            }
        case .enum:
            return (value as? EnumPersistable)?.rawValue
        case .model, .embedded, .embeddedCollection:
            return nil
        case .string, .double, .int:
            return String(describing: value)
        default:
            return nil
        }
    }

    private func getFieldValue(for modelFieldName: String, modelSchema: ModelSchema) -> Any?? {
        if let jsonModel = self as? JSONValueHolder {
            return jsonModel.jsonValue(for: modelFieldName, modelSchema: modelSchema) ?? nil
        } else {
            return self[modelFieldName] ?? nil
        }
    }
}
