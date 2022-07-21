//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// The raw response coming back from the AppSync GraphQL service
enum AWSAppSyncGraphQLResponse {
    case data(_ graphQLData: [String: JSONValue])
    case errors(_ graphQLErrors: [JSONValue])
    case partial(graphQLData: [String: JSONValue], graphQLErrors: [JSONValue])
    case invalidResponse

    static func decodeToAWSAppSyncGraphQLResponse(response: Data) throws -> AWSAppSyncGraphQLResponse {
        let jsonObject = try deserializeObject(graphQLResponse: response)
        do {
            let errors = try getAPIErrors(from: jsonObject)
            let data = try getGraphQLData(from: jsonObject)
            switch (data, errors) {
            case (nil, nil):
                return .invalidResponse
            case (.some(let data), .none):
                return .data(data)
            case (.none, .some(let errors)):
                return .errors(errors)
            case (.some(let data), .some(let errors)):
                return .partial(graphQLData: data, graphQLErrors: errors)
            }
        } catch is APIError {
            return .invalidResponse
        } catch {
            throw error
        }
    }

    private static func deserializeObject(graphQLResponse: Data) throws -> [String: JSONValue] {
        let json: JSONValue

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            json = try decoder.decode(JSONValue.self, from: graphQLResponse)
        } catch {
            throw APIError.operationError("Could not decode to JSONValue from the GraphQL Response",
                                          "Service issue",
                                          error)
        }

        guard case .object(let jsonObject) = json else {
            throw APIError.unknown("The GraphQL response is not an object",
                                   "The AppSync service returned a malformed GraphQL response")
        }

        return jsonObject
    }

    private static func getAPIErrors(from jsonObject: [String: JSONValue]) throws -> [JSONValue]? {
        guard let errors = jsonObject["errors"] else {
            return nil
        }

        guard case .array(let errorArray) = errors else {
            throw APIError.unknown("The GraphQL response containing errors should be an array",
                                   "The AppSync service returned a malformed GraphQL response")
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
                                   "The AppSync service returned a malformed GraphQL response")
        }
    }
}
