//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class APIRequestUtils {

    // TODO: path could be optional
    // Construct a URL given the url and path
    static func constructURL(_ baseURL: URL, path: String) throws -> URL {

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL("Invalid URL: \(baseURL.absoluteString)",
                """
                Review your API plugin configuration and ensure \(baseURL.absoluteString) is a valid URL for
                the 'Endpoint' field.
                """
            )
        }

        if components.path.isEmpty {
            components.path = path
        } else {
            components.path.append(path)
        }

        guard let url = components.url else {
            throw APIError.invalidURL(
                "Invalid URL for \(baseURL.absoluteString)",
                """
                Review your API plugin configuration and ensure \(baseURL.absoluteString) has a valid URL for the
                'Endpoint' field, and make sure to pass a valid path in your request. The value passed was '\(path)'.
                """
            )
        }

        return url
    }

    // Construct a request specific to the `APIOperationType`
    static func constructRequest(with url: URL,
                                 operationType: APIOperationType,
                                 requestPayload: Data?) -> URLRequest {

        var baseRequest = URLRequest(url: url)
        let headers = ["content-type": "application/json"]
        baseRequest.allHTTPHeaderFields = headers

        switch operationType {
        case .get:
            baseRequest.httpMethod = "GET"
        case .put:
            baseRequest.httpMethod = "PUT"
        case .post:
            baseRequest.httpMethod = "POST"
            if let requestPayload = requestPayload {
                baseRequest.httpBody = requestPayload
            }
        case .patch:
            baseRequest.httpMethod = "PATCH"
        case .delete:
            baseRequest.httpMethod = "DELETE"
        }

        return baseRequest
    }
}
