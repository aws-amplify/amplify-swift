//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SmithyHTTPAPI

@_spi(FoundationClientEngine)
public struct FoundationClientEngine: HTTPClient {
    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        let urlRequest = try await URLRequest(from: request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
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

    public init() {}

    /// no-op
    func close() async {}
}
