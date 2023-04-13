//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

@_spi(InternalAmplifyPluginExtension)
public class UserAgentSuffixAppender: AWSPluginExtension {
    public let suffix: String
    private let userAgentHeader = "User-Agent"
    private var httpClientEngine: HttpClientEngine? = nil

    public init(suffix: String) {
        self.suffix = suffix
    }
}

@_spi(InternalCustomHttpEngine)
extension UserAgentSuffixAppender: HttpClientEngine {
    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        guard let httpClientEngine = httpClientEngine  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }
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
        await httpClientEngine?.close()
    }

    public func setHttpClientEngine(_ httpClientEngine: HttpClientEngine) {
        self.httpClientEngine = httpClientEngine
    }
}
