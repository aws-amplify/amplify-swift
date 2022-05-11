//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias GraphQLInput = [String: Any?]

/// Extension that adds GraphQL specific utilities to concret types of `Model`.
extension Model {

    /// Get the `Model` values as a `Dictionary` of `String` to `Any?` that can be
    /// used as the `input` of GraphQL related operations.
    func graphQLInputForMutation(_ modelSchema: ModelSchema) -> GraphQLInput {
        var input: GraphQLInput = [:]
        modelSchema.fields.forEach {
            let modelField = $0.value

            // When the field is read-only don't add it to the GraphQL input object
            if modelField.isReadOnly {
                return
            }

            // TODO how to handle associations of type "many" (i.e. cascade save)?
            // This is not supported right now and might be added as a future feature
            if case .collection = modelField.type {
                return
            }

            let name = modelField.graphQLName
            let fieldValueOptional = getFieldValue(for: modelField.name, modelSchema: modelSchema)

            // Since the returned value is Any?? we need to do the following:
            // - `guard` to make sure the field name exists on the model
            // - `guard` to ensure the returned value isn't nil
            guard let fieldValue = fieldValueOptional else {
                input.updateValue(nil, forKey: name)
                return
            }

            // swiftlint:disable:next syntactic_sugar
            guard case .some(Optional<Any>.some(let value)) = fieldValue else {
                input.updateValue(nil, forKey: name)
                return
            }

            switch modelField.type {
            case .date, .dateTime, .time:
                if let date = value as? TemporalSpec {
                    input[name] = date.iso8601String
                } else {
                    input[name] = value
                }
            case .enum:
                input[name] = (value as? EnumPersistable)?.rawValue
            case .model:
                let fieldName = getFieldNameForAssociatedModels(modelField: modelField)
                input[fieldName] = getModelId(from: value, modelSchema: modelSchema)
            case .embedded, .embeddedCollection:
                if let encodable = value as? Encodable {
                    let jsonEncoder = JSONEncoder(dateEncodingStrategy: ModelDateFormatting.encodingStrategy)
                    do {
                        let data = try jsonEncoder.encode(encodable.eraseToAnyEncodable())
                        input[name] = try JSONSerialization.jsonObject(with: data)
                    } catch {
                        return Amplify.preconditionFailure("Could not turn into json object from \(value)")
                    }
                }
            case .string:
                // The input may contain the same keys from `.model` case when the `getFieldNameForAssociatedModels`
                // returns the same value as the `modelField.name`. If this is the case, let the `.model` case take
                // precedent over the explicit string field on the Model by ignoring the value that is about to be added
                if !input.keys.contains(name) {
                    input[name] = value
                }
            default:
                input[name] = value
            }
        }

        return fixHasOneAssociationsWithExplicitFieldOnModel(input, modelSchema: modelSchema)
    }

    /// This is to account for Models with an explicit field on the Model along with an object representing the hasOne
    /// association to another model. See https://github.com/aws-amplify/amplify-ios/issues/920 for more details.
    /// When the associated object is `nil`, remove the key from the GraphQL input to prevent runtime failures.
    /// When the associated object is found, take this value over the explicit field's value by replacing the correct
    /// entry for the field name of the associated model.
    private func fixHasOneAssociationsWithExplicitFieldOnModel(_ input: GraphQLInput,
                                                               modelSchema: ModelSchema) -> GraphQLInput {
        var input = input
        modelSchema.fields.forEach {
            let modelField = $0.value
            if case .model = modelField.type,
               case .hasOne = modelField.association,
               input.keys.contains(modelField.name) {

                let modelIdOrNilOptional = input[modelField.name]
                // swiftlint:disable:next syntactic_sugar
                guard case .some(Optional<Any>.some(let modelIdOrNil)) = modelIdOrNilOptional else {
                    input.removeValue(forKey: modelField.name)
                    return
                }
                if let modelIdValue = modelIdOrNil as? String {
                    let fieldName = getFieldNameForAssociatedModels(modelField: modelField)
                    input[fieldName] = modelIdValue
                }
            }
        }

        return input
    }

    /// Retrieve the custom primary key's value used for the GraphQL input.
    /// Only a subset of data types are applicable as custom indexes such as
    /// `date`, `dateTime`, `time`, `enum`, `string`, `double`, and `int`.
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

    private func getModelId(from value: Any, modelSchema: ModelSchema) -> String? {
        if let modelValue = value as? Model {
            return modelValue.id
        } else if let value = value as? [String: JSONValue],
                  case .string(let primaryKeyValue) = value[modelSchema.primaryKey.name] {
            return primaryKeyValue
        }

        return nil
    }

    private func getFieldValue(for modelFieldName: String, modelSchema: ModelSchema) -> Any?? {
        if let jsonModel = self as? JSONValueHolder {
            return jsonModel.jsonValue(for: modelFieldName, modelSchema: modelSchema) ?? nil
        } else {
            return self[modelFieldName] ?? nil
        }
    }

    /// Retrieves the GraphQL field name that associates the current model with the target model.
    /// By default, this is the current model + the associated Model + "Id", For example "comment" + "Post" + "Id"
    /// This information is also stored in the schema as `targetName` which is codegenerated to be the same as the
    /// default or an explicit field specified by the developer.
    private func getFieldNameForAssociatedModels(modelField: ModelField) -> String {
        let defaultFieldName = modelName.camelCased() + modelField.name.pascalCased() + "Id"
        if case let .belongsTo(_, targetName) = modelField.association {
            return targetName ?? defaultFieldName
        } else if case let .hasOne(_, targetName) = modelField.association {
            return targetName ?? defaultFieldName
        }

        return defaultFieldName
    }

}
