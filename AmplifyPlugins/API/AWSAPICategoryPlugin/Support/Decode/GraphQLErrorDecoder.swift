//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AppSyncRealTimeClient
import Foundation

struct GraphQLErrorDecoder {
    static func decodeErrors(graphQLErrors: [JSONValue]) throws -> [GraphQLError] {
        var responseErrors = [GraphQLError]()
        for error in graphQLErrors {
            do {
                let responseError = try decode(graphQLErrorJSON: error)
                responseErrors.append(responseError)
            } catch let decodingError as DecodingError {
                throw APIError(error: decodingError)
            } catch {
                throw APIError.unknown("""
                    Unexpected failure while decoding GraphQL response containing errors:
                    \(String(describing: graphQLErrors))
                    """, "", error)
            }
        }

        return responseErrors
    }

    static func decodeAppSyncErrors(_ appSyncJSON: AppSyncJSONValue) throws -> [GraphQLError] {
        guard case let .array(errors) = appSyncJSON else {
            throw APIError.unknown("Expected 'errors' field not found in \(String(describing: appSyncJSON))", "", nil)
        }
        let convertedValues = errors.map(AppSyncJSONValue.toJSONValue)
        return try decodeErrors(graphQLErrors: convertedValues)
    }

    static func decode(graphQLErrorJSON: JSONValue) throws -> GraphQLError {
        let serializedJSON = try JSONEncoder().encode(graphQLErrorJSON)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        let graphQLError = try decoder.decode(GraphQLError.self, from: serializedJSON)
        return mergeExtensions(from: graphQLErrorJSON, graphQLError: graphQLError)
    }

    /// Merge fields which are not in the generic GraphQL error json over into the `GraphQLError.extensions`
    /// This is the opinionated implementation of the plugin to store service errors which do not conform to the
    /// GraphQL Error spec (https://spec.graphql.org/June2018/#sec-Errors)
    private static func mergeExtensions(from graphQLErrorJSON: JSONValue, graphQLError: GraphQLError) -> GraphQLError {
        var keys = ["message", "locations", "path", "extensions"]
        var mergedExtensions = [String: JSONValue]()
        if let graphQLErrorExtensions = graphQLError.extensions {
            mergedExtensions = graphQLErrorExtensions
            keys += mergedExtensions.keys
        }

        guard case let .object(graphQLErrorObject) = graphQLErrorJSON else {
            return graphQLError
        }

        graphQLErrorObject.forEach { key, value in
            if keys.contains(key) {
                return
            }

            mergedExtensions[key] = value
        }

        return GraphQLError(message: graphQLError.message,
                            locations: graphQLError.locations,
                            path: graphQLError.path,
                            extensions: mergedExtensions.isEmpty ? nil : mergedExtensions)
    }
}
