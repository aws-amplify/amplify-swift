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
    public var target: HttpClientEngine? = nil
    public let suffix: String
    private let userAgentHeader = "User-Agent"

    public init(suffix: String) {
        self.suffix = suffix
    }
}

@_spi(InternalHttpEngineProxy)
extension UserAgentSuffixAppender: HttpClientEngine {
    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        guard let target = target  else {
            throw ClientError.unknownError("HttpClientEngine is not set")
        }
        #warning("need to mutate headers... maybe")
//        var headers = request.headers
//        let currentUserAgent = headers.value(for: userAgentHeader) ?? ""
//        headers.update(
//            name: userAgentHeader,
//            value: "\(currentUserAgent) \(suffix)"
//        )
//        request.headers = headers
        return try await target.execute(request: request)
    }
}
