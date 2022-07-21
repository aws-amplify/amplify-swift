//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

final class RESTOperationRequestUtils {
    private init() {

    }

    static func constructURL(for baseURL: URL,
                             with path: String?,
                             with queryParameters: [String: String]?) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL("Invalid URL: \(baseURL.absoluteString)",
                """
                Review your API plugin configuration and ensure \(baseURL.absoluteString) is a valid URL for
                the 'Endpoint' field.
                """
            )
        }

        if let path = path {
            components.path.append(path)
        }

        try components.encodeQueryItemsPerSigV4Rules(queryParameters)

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
    static func constructURLRequest(with url: URL,
                                    operationType: RESTOperationType,
                                    headers: [String: String]?,
                                    requestPayload: Data?) -> URLRequest {

        var baseRequest = URLRequest(url: url)
        var requestHeaders = ["content-type": "application/json"]
        if let headers = headers {
            for (key, value) in headers {
                requestHeaders[key] = value
            }
        }
        baseRequest.allHTTPHeaderFields = requestHeaders
        baseRequest.httpMethod = operationType.rawValue
        baseRequest.httpBody = requestPayload
        return baseRequest
    }
}
