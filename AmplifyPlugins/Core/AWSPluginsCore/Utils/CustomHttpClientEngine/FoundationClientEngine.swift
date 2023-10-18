//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import Amplify

@_spi(FoundationClientEngine)
public struct FoundationClientEngine: HttpClientEngine {
    public func execute(request: ClientRuntime.SdkHttpRequest) async throws -> ClientRuntime.HttpResponse {
        let urlRequest = try await URLRequest(sdkRequest: request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpURLResponse = response as? HTTPURLResponse else {
            // This shouldn't be necessary because we're only making HTTP requests.
            // `URLResponse` should always be a `HTTPURLResponse`.
            // But to refrain from crashing consuming applications, we're throwing here.
            throw FoundationClientEngineError.invalidURLResponse(urlRequest: response)
        }

        let httpResponse = try HttpResponse(
            httpURLResponse: httpURLResponse,
            data: data
        )

        return httpResponse
    }

    public init() {}

    /// no-op
    func close() async {}
}
