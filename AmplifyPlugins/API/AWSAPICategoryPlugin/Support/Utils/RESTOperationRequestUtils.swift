//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

final class RESTOperationRequestUtils {
    private init() {

    }

    static func constructURL(for baseURL: URL, with path: String?, with queryParameters: [String: String]?) throws -> URL {
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

        if let queryParameters = queryParameters {
            for queryParameter in queryParameters {
                let queryItem = URLQueryItem(name: queryParameter.key, value: queryParameter.value)
                components.queryItems?.append(queryItem)
            }
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

    // Construct a request specific to the `RESTOperationType`
    static func constructURLRequest(with url: URL,
                                    operationType: RESTOperationType,
                                    requestPayload: Data?) -> URLRequest {

        var baseRequest = URLRequest(url: url)
        let headers = ["content-type": "application/json"]
        baseRequest.allHTTPHeaderFields = headers
        baseRequest.httpMethod = operationType.rawValue
        baseRequest.httpBody = requestPayload


        switch operationType {
        case .get:
            break
        case .put:
            break
        case .post:
            break
        case .patch:
            break
        case .delete:
            break
        case .head:
            break
        }

        return baseRequest
    }
}
