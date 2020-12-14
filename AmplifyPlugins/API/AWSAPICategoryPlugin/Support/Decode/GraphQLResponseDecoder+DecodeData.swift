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
                return try decodeToModelWithConnections(graphQLData: graphQLData) ?? responseData
            } else if responseData is ModelListMarker {
                return try decodeToAppSyncList(graphQLData: graphQLData)
            }
            return responseData
        }
    }

    func decodeToModelWithConnections(graphQLData: JSONValue) throws -> R? {
        guard let modelName = try getModelName(graphQLData: graphQLData),
              let modelType = ModelRegistry.modelType(from: modelName) else {
            return nil
        }
        let arrayAssociations = modelType.schema.fields.values.filter {
            $0.isArray && $0.hasAssociation
        }
        guard !arrayAssociations.isEmpty,
              let id = try getId(graphQLData: graphQLData),
              case .object(var graphQLDataObject) = graphQLData else {
            return nil
        }

        // Iterate over the associations of the model and for each association, store it's association data
        // For example, if the modelType is a Post and has a field that is an array association like Comment
        // Store the post's id and post field in the comments as the `associationPayload`
        modelType.schema.fields.values.forEach { modelField in
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField {
                let modelFieldName = modelField.name
                let associatedFieldName = associatedField.name

                if graphQLData[modelFieldName] == nil {
                    let associationPayload: JSONValue = [
                        "associatedId": .string(id),
                        "associatedField": .string(associatedFieldName),
                        "listType": "appSyncList"
                    ]

                    graphQLDataObject.updateValue(associationPayload, forKey: modelFieldName)
                }
            }
        }
        let serializedJSON = try encoder.encode(graphQLDataObject)
        return try decoder.decode(request.responseType, from: serializedJSON)
    }

    func getModelName(graphQLData: JSONValue) throws -> String? {
        guard case .string(let typename) = graphQLData["__typename"] else {
            Amplify.API.log.error("""
                Could not retrieve the `__typename` attribute from the return value. Be sure to include __typename in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """)
            return nil
        }

        return typename
    }

    func getId(graphQLData: JSONValue) throws -> String? {
        guard case .string(let id) = graphQLData["id"] else {
            Amplify.API.log.error("""
                Could not retrieve the `id` attribute from the return value. Be sure to include `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
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
