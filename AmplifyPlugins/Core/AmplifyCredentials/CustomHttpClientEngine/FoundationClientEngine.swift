//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SmithyHTTPAPI

@_spi(FoundationClientEngine)
public struct FoundationClientEngine: HTTPClient {
    let urlSession: URLSession

    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        let urlRequest = try await URLRequest(from: request)

        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpURLResponse = response as? HTTPURLResponse else {
            // This shouldn't be necessary because we're only making HTTP requests.
            // `URLResponse` should always be a `HTTPURLResponse`.
            // But to refrain from crashing consuming applications, we're throwing here.
            throw FoundationClientEngineError.invalidURLResponse(urlRequest: response)
        }

        let httpResponse = try HTTPResponse(
            httpURLResponse: httpURLResponse,
            data: data
        )

        return httpResponse
    }

    public init() {
        // These requests carry Cognito tokens and AWS credentials. Disable URL
        // caching so that responses are never persisted to disk (e.g. Cache.db),
        // where they could be recovered by inspecting the app container. This
        // mirrors the cache-disabling behavior used for the Hosted UI session.
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: configuration)
    }

    /// no-op
    func close() async {}
}
