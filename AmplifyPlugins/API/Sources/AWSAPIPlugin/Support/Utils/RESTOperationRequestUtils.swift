//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

final class RESTOperationRequestUtils {
    private init() {}

    static func constructURL(
        for baseURL: URL,
        withPath path: String?,
        withParams queryParameters: [String: String]?
    ) throws -> URL {
        guard var components = URLComponents(
            url: baseURL,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL(
                "Invalid URL: \(baseURL.absoluteString)",
                """
                Review your API plugin configuration and ensure \(baseURL.absoluteString) is a valid URL for
                the 'Endpoint' field.
                """
            )
        }

        if let path = path {
            components.path.append(path)
        }

        if let queryParameters = queryParameters {
            components.queryItems = try prepareQueryParamsForSigning(params: queryParameters)
        }

        guard let url = components.url else {
            throw APIError.invalidURL(
                "Invalid URL for \(baseURL.absoluteString)",
                """
                Review your API plugin configuration and ensure \(baseURL.absoluteString) has a valid URL for the
                'Endpoint' field, and make sure to pass a valid path in your request. The value passed was
                '\(path ?? "nil")'.
                """
            )
        }

        return url
    }

    // Construct a request specific to the `RESTOperationType`
    static func constructURLRequest(
        with url: URL,
        operationType: RESTOperationType,
        requestPayload: Data?
    ) -> URLRequest {
        var baseRequest = URLRequest(url: url)
        baseRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        baseRequest.httpMethod = operationType.rawValue
        baseRequest.httpBody = requestPayload
        return baseRequest
    }

    private static let permittedQueryParamCharacters = CharacterSet.alphanumerics
        .union(.init(charactersIn: "/_-.~"))

    private static func prepareQueryParamsForSigning(params: [String: String]) throws -> [URLQueryItem] {
        // remove percent encoding to prepare for request signing
        // `removingPercentEncoding` is a no-op if the query isn't encoded
        func removePercentEncoding(key: String, value: String) -> (String, String) {
            (key.removingPercentEncoding ?? key, value.removingPercentEncoding ?? value)
        }

        // Disallowed characters are checked for in the Swift SDK. However it effectively silently fails
        // there by removing any invalid parameters. We're conducting this check here to inform the call-
        // site.
        func confirmOnlyPermittedCharactersPresent(key: String, value: String) throws -> (String, String) {
            guard value.rangeOfCharacter(from: permittedQueryParamCharacters) != nil,
                key.rangeOfCharacter(from: permittedQueryParamCharacters) != nil
            else {
                throw APIError.invalidURL(
                    "Invalid query parameter.",
                    """
                    Review your Amplify.API call to make sure you are passing \
                    valid UTF-8 query parameters in your request.
                    The value passed was '\(key)=\(value)'
                    """
                )
            }
            return (key, value)
        }

        let queryItems = try params
            .map(removePercentEncoding)
            .map(confirmOnlyPermittedCharactersPresent)
            .map(URLQueryItem.init)

        return queryItems
    }
}
