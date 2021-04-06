//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

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
        }

        let serializedJSON: Data
        if request.responseType == AnyModel.self {
            let anyModel = try AnyModel(modelJSON: graphQLData)
            serializedJSON = try encoder.encode(anyModel)
        } else if request.responseType is ModelListMarker.Type {
            let payload = AppSyncListPayload(graphQLData: graphQLData,
                                             apiName: request.apiName,
                                             variables: try getVariablesJSON())
            serializedJSON = try encoder.encode(payload)
        } else if AppSyncModelMetadataUtils.shouldAddMetadata(toModel: graphQLData) {
            let modelJSON = AppSyncModelMetadataUtils.addMetadata(toModel: graphQLData,
                                                                  apiName: request.apiName)
            serializedJSON = try encoder.encode(modelJSON)
        } else {
            serializedJSON = try encoder.encode(graphQLData)
        }

        return try decoder.decode(request.responseType, from: serializedJSON)
    }

    // MARK: - Helper methods

    private func valueAtDecodePath(from graphQLData: JSONValue) throws -> JSONValue {
        guard let decodePath = request.decodePath else {
            return graphQLData
        }

        guard let model = graphQLData.value(at: decodePath) else {
            throw APIError.operationError("Could not retrieve object, given decode path: \(decodePath)", "", nil)
        }

        return model
    }

    private func getVariablesJSON() throws -> [String: JSONValue]? {
        guard let variables = request.variables else {
            return nil
        }

        let variablesData = try JSONSerialization.data(withJSONObject: variables)
        return try decoder.decode([String: JSONValue].self, from: variablesData)
    }
}
