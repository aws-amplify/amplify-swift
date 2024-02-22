//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

@_spi(InternalAmplifyPluginExtension)
public class UserAgentSuffixAppender: AWSPluginExtension {
    @_spi(InternalHttpEngineProxy)
    public var target: HTTPClient?
    public let suffix: String
    private let userAgentKey = "User-Agent"

    public init(suffix: String) {
        self.suffix = suffix
    }
}

@_spi(InternalHttpEngineProxy)
extension UserAgentSuffixAppender: HTTPClient {
    public func send(request: SdkHttpRequest) async throws -> HttpResponse {
        guard let target = target  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }

        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let userAgent = "\(existingUserAgent) \(suffix)"
        let request = request.updatingUserAgent(with: userAgent)

        return try await target.send(request: request)
    }
}
