//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

final class RESTRequestUtils {
    private init() {

    }
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

        // TODO: fix this:
        /*
         This code will not do anything for the case of a base URL like
         baseURL = http://foo.com/bar;
         path = "/baz" where the expectation is that the final URL is http://foo.com/bar/baz
         */
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

    // Construct a request specific to the `RESTOperationType`
    static func constructRequest(with url: URL,
                                 operationType: RESTOperationType,
                                 requestPayload: Data?) -> URLRequest {

        var baseRequest = URLRequest(url: url)
        let headers = ["content-type": "application/json"]
        baseRequest.allHTTPHeaderFields = headers

        baseRequest.httpMethod = operationType.rawValue
        switch operationType {
        case .get:
            break
        case .put:
            break
        case .post:
            baseRequest.httpBody = requestPayload
        case .patch:
            break
        case .delete:
            break
        }

        return baseRequest
    }
}
