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
    
    /*
     The sequence of `responseType` checking attempts to decode to specific types before falling back to (5)
     serializing the data and letting the default decode run its course (6).
     
     1. String, special case where the object is serialized as a JSON string.
     2. AnyModel, used by DataStore's sync engine
     3. ModelListMarker, checks if it is a List type, inject additional information to create a loaded list.
     4. AppSyncModelMetadataUtils.shouldAddMetadata/addMetadata injects metadata recursively
        decode to nested notloaded Lists.
     5. Default encode/decode path
     */
    func decodeToResponseType(_ graphQLData: [String: JSONValue]) throws -> R {
        var graphQLData = try valueAtDecodePath(from: JSONValue.object(graphQLData))
        if request.responseType == String.self { // 1
            let serializedJSON = try encoder.encode(graphQLData)
            guard let responseString = String(data: serializedJSON, encoding: .utf8) else {
                throw APIError.operationError("Could not get String from data", "", nil)
            }
            guard let response = responseString as? R else {
                throw APIError.operationError("Not of type \(String(describing: R.self))", "", nil)
            }
            return response
        }

        if let graphQLDataWithTypeName = shouldAddTypename(to: graphQLData) {
            graphQLData = graphQLDataWithTypeName
        }
        let serializedJSON: Data
        
        if request.responseType == AnyModel.self { // 2
            let anyModel = try AnyModel(modelJSON: graphQLData)
            serializedJSON = try encoder.encode(anyModel)
        } else if request.responseType is ModelListMarker.Type, // 3
                  case .object(var graphQLDataObject) = graphQLData,
                  case .array(var graphQLDataArray) = graphQLDataObject["items"] {
            for (index, item) in graphQLDataArray.enumerated() {
                let modelJSON = AppSyncModelMetadataUtils.addMetadata(toModel: item,
                                                                      apiName: request.apiName)
                graphQLDataArray[index] = modelJSON
            }
            graphQLDataObject["items"] = JSONValue.array(graphQLDataArray)
            let payload = AppSyncListPayload(graphQLData: JSONValue.object(graphQLDataObject),
                                             apiName: request.apiName,
                                             variables: try getVariablesJSON())
            serializedJSON = try encoder.encode(payload)
        } else if AppSyncModelMetadataUtils.shouldAddMetadata(toModel: graphQLData) { // 4
            let modelJSON = AppSyncModelMetadataUtils.addMetadata(toModel: graphQLData,
                                                                  apiName: request.apiName)
            serializedJSON = try encoder.encode(modelJSON)
        } else { // 5
            serializedJSON = try encoder.encode(graphQLData)
        }

        return try decoder.decode(request.responseType, from: serializedJSON) // 6
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
    
    // The Swift DataStore plugin has a dependency on using `__typename` from the response data.
    // For example, DataStore will use the type `MutationSync<AnyModel>` to decode the model with sync metadata by
    // pulling out the modelName from `__typename` and use that to decode to the actual model type.
    // The selection set created by other platforms such as JS and Android does not contain the `__typename`
    // in the mutation request, which is one of the reasons for the decoding error when the mutation is sent from
    // Studio/JS/Android.
    //
    // This code injects the typename field at runtime for response payloads specifically used by DataStore,
    // `MutationSync<AnyModel>`, so that that the JS/Android sourced subscription events decode successfully.
    //
    // Since we are injecting the typename into the response payload, do we still need to request it from the service?
    // Yes, because mutations sourced from the new iOS clients sent to old iOS clients should be able to decode
    // successfully. We're enabling new use cases (successful decoding of Studio/JS/Android sourced mutations) but
    // should not break iOS upgrade use cases without a major version bump. iOS users that haven't upgraded to the
    // latest version of the developer's app will continue to work because the the mutation request sent from the
    // latest library continues to have the typename field.
    private func shouldAddTypename(to graphQLData: JSONValue) -> JSONValue? {
        if let modelName = modelName,
           request.responseType == MutationSync<AnyModel>.self,
           case var .object(modelJSON) = graphQLData,
           // No need to replace existing response payloads that have it already
           modelJSON["__typename"] == nil {
            modelJSON["__typename"] = .string(modelName)
            return JSONValue.object(modelJSON)
        } else {
            return nil
        }
    }
}
