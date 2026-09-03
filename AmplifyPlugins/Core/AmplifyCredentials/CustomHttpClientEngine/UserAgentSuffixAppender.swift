//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import SmithyHTTPAPI

/// - Note: `final` and `@unchecked Sendable` so it can satisfy `AWSPluginExtension`'s `Sendable`
///   requirement. `target` is assigned by the plugin after construction, so it stays mutable and
///   access is serialized by `lock`.
@_spi(InternalAmplifyPluginExtension)
public final class UserAgentSuffixAppender: AWSPluginExtension, @unchecked Sendable {
    private let lock = NSLock()
    private var _target: HTTPClient?

    @_spi(InternalHttpEngineProxy)
    public var target: HTTPClient? {
        get { lock.withLock { _target } }
        set { lock.withLock { _target = newValue } }
    }

    public let suffix: String
    private let userAgentKey = "User-Agent"

    public init(suffix: String) {
        self.suffix = suffix
    }
}

@_spi(InternalHttpEngineProxy)
extension UserAgentSuffixAppender: HTTPClient {
    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        guard let target  else {
            throw Smithy.ClientError.unknownError("HttpClientEngine is not set")
        }

        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let userAgent = "\(existingUserAgent) \(suffix)"
        let request = request.updatingUserAgent(with: userAgent)

        return try await target.send(request: request)
    }
}
