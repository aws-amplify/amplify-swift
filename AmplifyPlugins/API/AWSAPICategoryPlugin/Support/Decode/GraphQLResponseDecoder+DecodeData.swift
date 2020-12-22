//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

extension GraphQLResponseDecoder {

    func decodeToResponseType(_ graphQLData: [String: JSONValue]) throws -> R {
        let graphQLData = try valueAtDecodePath(from: JSONValue.object(graphQLData))
        if request.responseType == String.self {
            let serializedJSON = try encoder.encode(graphQLData)
            guard let responseString = String(data: serializedJSON, encoding: .utf8) else {
                throw APIError.operationError("Could not get String from data", "", nil)
            }
            guard let response = responseString as? R else {
                throw APIError.operationError("Not of type \(String(describing: R.self))", "", nil)
            }
            return response
        } else if request.responseType == AnyModel.self {
            let anyModel = try AnyModel(modelJSON: graphQLData)
            let serializedJSON = try encoder.encode(anyModel)
            return try decoder.decode(request.responseType, from: serializedJSON)
        } else {
            let serializedJSON = try encoder.encode(graphQLData)
            let responseData = try decoder.decode(request.responseType, from: serializedJSON)
            if responseData is Model {
                return try GraphQLResponseDecoder.decodeToModelWithArrayAssociations(responseType: request.responseType,
                                                                                     modelGraphQLData: graphQLData)
            } else if responseData is ModelListMarker {
                return try decodeToAppSyncList(graphQLData: graphQLData)
            }
            return responseData
        }
    }

    static func decodeToModelWithArrayAssociations<M: Decodable>(responseType: M.Type,
                                                                 modelGraphQLData: JSONValue) throws -> M {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy

        guard let modelType = getModelType(modelGraphQLData: modelGraphQLData),
              let id = getId(modelGraphQLData: modelGraphQLData),
              case .object(var model) = modelGraphQLData else {
            let serializedJSON = try encoder.encode(modelGraphQLData)
            return try decoder.decode(M.self, from: serializedJSON)
        }

        // Iterate over the associations of the model and for each association, store it's association data
        // For example, if the modelType is a Post and has a field that is an array association like Comment
        // Store the post's id and post field in the comments as the `associationPayload`
        modelType.schema.fields.values.forEach { modelField in
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField {
                let modelFieldName = modelField.name
                let associatedFieldName = associatedField.name

                if model[modelFieldName] == nil {
                    let associationPayload: JSONValue = [
                        "associatedId": .string(id),
                        "associatedField": .string(associatedFieldName),
                        "listType": "appSyncList"
                    ]

                    model.updateValue(associationPayload, forKey: modelFieldName)
                }
            }
        }
        let serializedJSON = try encoder.encode(model)
        return try decoder.decode(M.self, from: serializedJSON)
    }

    private static func getModelType(modelGraphQLData: JSONValue) -> Model.Type? {
        guard case .string(let modelName) = modelGraphQLData["__typename"],
              let modelType = ModelRegistry.modelType(from: modelName) else {
            Amplify.API.log.error("""
                Could not retrieve the `__typename` attribute from the return value. Be sure to include __typename in \
                the selection set of the GraphQL operation. GraphQL:
                \(modelGraphQLData)
                """)
            return nil
        }

        return modelType
    }

    private static func getId(modelGraphQLData: JSONValue) -> String? {
        guard case .string(let id) = modelGraphQLData["id"] else {
            Amplify.API.log.error("""
                Could not retrieve the `id` attribute from the return value. Be sure to include `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(modelGraphQLData)
                """)
            return nil
        }

        return id
    }

    func decodeToAppSyncList(graphQLData: JSONValue) throws -> R {
        let payload: AppSyncListPayload
        if let variables = request.variables {
            let variablesData = try JSONSerialization.data(withJSONObject: variables)
            let variablesJSON = try decoder.decode([String: JSONValue].self, from: variablesData)
            payload = AppSyncListPayload(document: request.document,
                                         variables: variablesJSON,
                                         graphQLData: graphQLData)
        } else {
            payload = AppSyncListPayload(document: request.document,
                                         graphQLData: graphQLData)
        }

        let encodedData = try encoder.encode(payload)
        return try decoder.decode(request.responseType, from: encodedData)
    }

    private func valueAtDecodePath(from graphQLData: JSONValue) throws -> JSONValue {
        guard let decodePath = request.decodePath else {
            return graphQLData
        }

        guard let model = graphQLData.value(at: decodePath) else {
            throw APIError.operationError("Could not retrieve object, given decode path: \(decodePath)", "", nil)
        }

        return model
    }
}
