//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAPI
import Smithy

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
    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        guard let target = target  else {
            throw Smithy.ClientError.unknownError("HttpClientEngine is not set")
        }

        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let userAgent = "\(existingUserAgent) \(suffix)"
        let request = request.updatingUserAgent(with: userAgent)

        return try await target.send(request: request)
    }
}
