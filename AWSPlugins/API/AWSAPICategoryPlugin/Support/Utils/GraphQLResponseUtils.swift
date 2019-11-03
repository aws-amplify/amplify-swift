//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class GraphQLResponseUtils {

    // Process a GraphQL response into a `GraphQLResponse`
    static func process<R: ResponseType>(graphQLResponse: Data,
                                         responseType: R) throws -> GraphQLResponse<R.SerializedObject> {
        let result = try deserialize(graphQLResponse: graphQLResponse)

        // Ensure validity of the response, there should at least be errors or data, or partial results (both)
        if result.errors.isEmpty && result.data == nil {
            throw GraphQLError.unknown("both cannot be nil", "service error")
        }

        // Return nil data and any errors when there is no data to process
        guard let responseData = result.data else {
            let responseType: R.SerializedObject? = nil
            return GraphQLResponse(data: responseType, errors: result.errors)
        }

        if responseData.isEmpty {
            let responseType: R.SerializedObject? = nil
            return GraphQLResponse(data: responseType, errors: result.errors)
        }

        // Process the first value and try to convert it the specified response type
        if responseData.count == 1 {
            let json = responseData.first!.value
            let responseData = try convert(json: json, responseType: responseType)
            return GraphQLResponse(data: responseData, errors: result.errors)
        }

        throw GraphQLError.unknown("More than one query is not yet supported",
                                   "Reduce the query document to single query")
    }

    // MARK: Helper methods for `process(graphQLResponse:Data,responseType:R)`

    // Deserialize GraphQL response
    // The structure of a GraphQL response is JSON containing "data" and "errors"
    static func deserialize(graphQLResponse: Data) throws -> (data: [String: JSONValue]?, errors: [JSONValue]) {
        let jsonObject = try deserializeObject(graphQLResponse: graphQLResponse)
        let processedErrors = try processErrors(jsonObject: jsonObject)
        let processedData = try processData(jsonObject: jsonObject)

        return (data: processedData, errors: processedErrors)
    }

    // Deserialize GraphQLResponse into JSON object
    static func deserializeObject(graphQLResponse: Data) throws -> [String: JSONValue] {
        let json: JSONValue
        do {
            json = try JSONDecoder().decode(JSONValue.self, from: graphQLResponse)
        } catch {
            throw GraphQLError.operationError("Could not deserialize response data",
                                               "Service issue",
                                               error)
        }

        guard case .object(let jsonObject) = json else {
            throw GraphQLError.unknown("Deserialized response data is not an object",
                                       "Service issue")
        }

        return jsonObject
    }

    // Extracts the errors from the `jsonObject` and ensure it is an array
    static func processErrors(jsonObject: [String: JSONValue]) throws -> [JSONValue] {
        if let errors = jsonObject["errors"] {

            guard case .array(let errorArray) = errors else {
                throw GraphQLError.unknown("Deserialized response error is not an array",
                                           "Service issue")
            }

            return errorArray
        }

        return [JSONValue]()
    }

    // Extracts the data from the `jsonObject` and ensure it is an object
    static func processData(jsonObject: [String: JSONValue]) throws -> [String: JSONValue]? {
        if let data = jsonObject["data"] {
            // 5. Make sure the data is an object (meaning, the keys are the query names)
            guard case .object(let dataObject) = data else {
                throw GraphQLError.unknown("Failed to case data object to dict",
                                           "Service issue")
            }

            return dataObject
        }

        return nil
    }

    // Convert the JSON to an instance of the response type
    static func convert<R: ResponseType>(json: JSONValue, responseType: R) throws -> R.SerializedObject? {
        if case .null = json {
            return nil
        }

        do {
            let serializedJson = try JSONEncoder().encode(json)
            return try JSONDecoder().decode(R.SerializedObject.self, from: serializedJson)
        } catch let decodingError as DecodingError {
            throw APIErrorMapper.handleDecodingError(error: decodingError)
        } catch {
            throw GraphQLError.operationError("", "", error)
        }
    }
}
