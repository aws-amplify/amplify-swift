//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

@_spi(InternalAmplifyUserAgent)
public struct UserAgentSuffixAppender: HttpClientEngine {
    private let userAgentHeader = "User-Agent"
    private let suffix: String
    private let httpClientEngine: HttpClientEngine

    public init(
        suffix: String,
        using httpClientEngine: HttpClientEngine
    ) {
        self.httpClientEngine = httpClientEngine
        self.suffix = suffix
    }

    public func execute(request: SdkHttpRequest) async throws -> ClientRuntime.HttpResponse {
        var headers = request.headers
        let currentUserAgent = headers.value(for: userAgentHeader) ?? ""
        headers.update(
            name: userAgentHeader,
            value: "\(currentUserAgent) \(suffix)"
        )
        request.headers = headers
        return try await httpClientEngine.execute(request: request)
    }

    public func close() async {
        await httpClientEngine.close()
    }
}
