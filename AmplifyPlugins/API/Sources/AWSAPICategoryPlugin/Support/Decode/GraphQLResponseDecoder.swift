//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class GraphQLResponseDecoder<R: Decodable> {

    let request: GraphQLOperationRequest<R>
    var response: Data
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    public init(request: GraphQLOperationRequest<R>, response: Data = Data()) {
        self.request = request
        self.response = response
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }

    func appendResponse(_ data: Data) {
        response.append(data)
    }

    func decodeToGraphQLResponse() throws -> GraphQLResponse<R> {
        let appSyncGraphQLResponse = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: response)
        switch appSyncGraphQLResponse {
        case .data(let data):
            return try decodeData(data)
        case .errors(let errors):
            return try decodeErrors(errors)
        case .partial(let data, let errors):
            return try decodePartial(graphQLData: data, graphQLErrors: errors)
        case .invalidResponse:
            guard let rawGraphQLResponseString = String(data: response, encoding: .utf8) else {
                throw APIError.operationError(
                    "Could not get the String representation of the GraphQL response", "")
            }
            throw APIError.unknown("The service returned some data without any `data` and `errors`",
                                   """
                                   The service did not return an expected GraphQL response: \
                                   \(rawGraphQLResponseString)
                                   """)
        }
    }

    func decodeData(_ graphQLData: [String: JSONValue]) throws -> GraphQLResponse<R> {
        do {
            let responseData = try decodeToResponseType(graphQLData)
            return GraphQLResponse<R>.success(responseData)
        } catch let decodingError as DecodingError {
            let error = APIError(error: decodingError)
            guard let rawGraphQLResponseString = String(data: response, encoding: .utf8) else {
                throw APIError.operationError(
                    "Could not get the String representation of the GraphQL response", "")
            }
            return GraphQLResponse<R>.failure(.transformationError(rawGraphQLResponseString, error))
        } catch {
            throw error
        }
    }

    func decodeErrors(_ graphQLErrors: [JSONValue]) throws -> GraphQLResponse<R> {
        let responseErrors = try GraphQLErrorDecoder.decodeErrors(graphQLErrors: graphQLErrors)
        return GraphQLResponse<R>.failure(.error(responseErrors))
    }

    func decodePartial(graphQLData: [String: JSONValue],
                       graphQLErrors: [JSONValue]) throws -> GraphQLResponse<R> {
        do {
            if let first = graphQLData.first, case .null = first.value {
                let responseErrors = try GraphQLErrorDecoder.decodeErrors(graphQLErrors: graphQLErrors)
                return GraphQLResponse<R>.failure(.error(responseErrors))
            }
            let responseData = try decodeToResponseType(graphQLData)
            let responseErrors = try GraphQLErrorDecoder.decodeErrors(graphQLErrors: graphQLErrors)
            return GraphQLResponse<R>.failure(.partial(responseData, responseErrors))
        } catch let decodingError as DecodingError {
            let error = APIError(error: decodingError)
            guard let rawGraphQLResponseString = String(data: response, encoding: .utf8) else {
                throw APIError.operationError(
                    "Could not get the String representation of the GraphQL response", "")
            }
            return GraphQLResponse<R>.failure(.transformationError(rawGraphQLResponseString, error))
        } catch {
            throw error
        }
    }
}
