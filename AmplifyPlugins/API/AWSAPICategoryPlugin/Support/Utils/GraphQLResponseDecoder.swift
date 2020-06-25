//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

struct GraphQLResponseDecoder {

    // TODO: code clean up - break the code in these case statements into separate methods
    static func decode<R: Decodable>(graphQLServiceResponse: AWSAppSyncGraphQLResponse,
                                     responseType: R.Type,
                                     decodePath: String?,
                                     rawGraphQLResponse: Data) throws -> GraphQLResponse<R> {

        switch (graphQLServiceResponse.data, graphQLServiceResponse.errors) {
        case (nil, nil):
            guard let rawGraphQLResponseString = String(data: rawGraphQLResponse, encoding: .utf8) else {
                throw APIError.operationError(
                    "Could not get the String of full graphql response containing data and errors", "")
            }

            throw APIError.unknown("The service returned some data without any `data` and `errors`",
                                   """
                                   The service did not return an expected GraphQL response: \
                                   \(rawGraphQLResponseString)
                                   """)

        case (.some(let data), .none):
            do {
                let jsonValue = JSONValue.object(data)
                let responseData = try decode(graphQLData: jsonValue,
                                              into: responseType,
                                              at: decodePath)
                return GraphQLResponse<R>.success(responseData)
            } catch let decodingError as DecodingError {
                let error = APIError(error: decodingError)
                guard let rawGraphQLResponseString = String(data: rawGraphQLResponse, encoding: .utf8) else {
                    throw APIError.operationError(
                        "Could not get the String of full graphql response containing data and errors", "")
                }
                return GraphQLResponse<R>.failure(.transformationError(rawGraphQLResponseString, error))
            } catch {
                throw error
            }

        case (.none, .some(let errors)):
            let responseErrors = try decodeErrors(graphQLErrors: errors)
            return GraphQLResponse<R>.failure(.error(responseErrors))

        case (.some(let data), .some(let errors)):
            do {
                if data.count == 1, let first = data.first, case .null = first.value {
                    let responseErrors = try decodeErrors(graphQLErrors: errors)
                    return GraphQLResponse<R>.failure(.error(responseErrors))
                }

                let jsonValue = JSONValue.object(data)
                let responseData = try decode(graphQLData: jsonValue,
                                              into: responseType,
                                              at: decodePath)
                let responseErrors = try decodeErrors(graphQLErrors: errors)
                return GraphQLResponse<R>.failure(.partial(responseData, responseErrors))
            } catch let decodingError as DecodingError {
                let error = APIError(error: decodingError)
                guard let rawGraphQLResponseString = String(data: rawGraphQLResponse, encoding: .utf8) else {
                    throw APIError.operationError(
                        "Could not get the String of full graphql response containing data and errors", "")
                }
                return GraphQLResponse<R>.failure(.transformationError(rawGraphQLResponseString, error))
            } catch {
                throw error
            }
        }
    }

    static func deserialize(graphQLResponse: Data) throws -> AWSAppSyncGraphQLResponse {
        let jsonObject = try deserializeObject(graphQLResponse: graphQLResponse)
        let errors = try getAPIErrors(from: jsonObject)
        let data = try getGraphQLData(from: jsonObject)

        return AWSAppSyncGraphQLResponse(data: data, errors: errors)
    }

    // MARK: - Private methods

    private static func deserializeObject(graphQLResponse: Data) throws -> [String: JSONValue] {
        let json: JSONValue

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            json = try decoder.decode(JSONValue.self, from: graphQLResponse)
        } catch {
            throw APIError.operationError("Could not deserialize response data",
                                          "Service issue",
                                          error)
        }

        guard case .object(let jsonObject) = json else {
            throw APIError.unknown("Deserialized response data is not an object",
                                   "Service issue")
        }

        return jsonObject
    }

    private static func getAPIErrors(from jsonObject: [String: JSONValue]) throws -> [JSONValue]? {
        guard let errors = jsonObject["errors"] else {
            return nil
        }

        guard case .array(let errorArray) = errors else {
            throw APIError.unknown("Deserialized response error is not an array",
                                   "Service issue")
        }

        return errorArray
    }

    private static func getGraphQLData(from jsonObject: [String: JSONValue]) throws -> [String: JSONValue]? {
        guard let data = jsonObject["data"] else {
            return nil
        }

        switch data {
        case .object(let dataObject):
            return dataObject
        case .null:
            return nil
        default:
            throw APIError.unknown("Failed to get object or null from data.",
                                   "Service issue")
        }
    }

    private static func decode<R: Decodable>(graphQLData: JSONValue,
                                             into responseType: R.Type,
                                             at decodePath: String?) throws -> R {

        let isAnyModel = responseType == AnyModel.self

        let serializedJSON = isAnyModel ?
            try serializeAnyModel(from: graphQLData, at: decodePath) :
            try serialize(graphQLData: graphQLData, at: decodePath)

        if responseType == String.self {

            guard let responseString = String(data: serializedJSON, encoding: .utf8) else {
                throw APIError.operationError("could not get string from data", "", nil)
            }

            guard let response = responseString as? R else {
                throw APIError.operationError("Not of type \(String(describing: R.self))", "", nil)
            }

            return response
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(responseType, from: serializedJSON)
    }

    private static func serialize(graphQLData: JSONValue,
                                  at decodePath: String?) throws -> Data {
        let modelJSON = try getModelJSONValue(from: graphQLData, at: decodePath)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(modelJSON)
    }

    private static func serializeAnyModel(from graphQLData: JSONValue,
                                          at decodePath: String?) throws -> Data {
        let modelJSON = try getModelJSONValue(from: graphQLData, at: decodePath)
        let anyModel = try AnyModel(modelJSON: modelJSON)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(anyModel)
    }

    private static func getModelJSONValue(from graphQLData: JSONValue,
                                          at decodePath: String?) throws -> JSONValue {
        guard let decodePath = decodePath else {
            return graphQLData
        }

        guard let model = graphQLData.value(at: decodePath) else {
            throw APIError.operationError("Could not retrieve object, given decode path: \(decodePath)", "", nil)
        }

        return model
    }
}
