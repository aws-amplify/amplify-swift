//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
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
            return responseData
        }
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
