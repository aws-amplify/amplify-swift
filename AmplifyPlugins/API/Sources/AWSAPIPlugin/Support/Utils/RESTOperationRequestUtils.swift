//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

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

        if let path {
            components.path.append(path)
        }

        if let queryParameters {
            components.queryItems = prepareQueryParamsForSigning(params: queryParameters)
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

    private static func prepareQueryParamsForSigning(params: [String: String]) -> [URLQueryItem] {
        // Remove percent encoding to prepare for request signing. `URLComponents` will
        // re-encode canonically when the URL is assembled, and the SigV4 signer works
        // off the decoded values. `removingPercentEncoding` is a no-op if the value
        // isn't encoded.
        params.map { key, value in
            URLQueryItem(
                name: key.removingPercentEncoding ?? key,
                value: value.removingPercentEncoding ?? value
            )
        }
    }
}
