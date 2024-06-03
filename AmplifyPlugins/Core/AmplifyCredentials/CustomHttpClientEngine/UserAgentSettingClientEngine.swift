//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import AWSClientRuntime

@_spi(PluginHTTPClientEngine)
public struct UserAgentSettingClientEngine: AWSPluginExtension {
    @_spi(InternalHttpEngineProxy)
    public let target: HTTPClient
    private let userAgentKey = "User-Agent"

    public init(target: HTTPClient) {
        self.target = target
    }
}

@_spi(PluginHTTPClientEngine)
extension UserAgentSettingClientEngine: HTTPClient {
    
    // CI updates the `platformName` property in `AmplifyAWSServiceConfiguration`.
    // We can / probably should move this in the future
    // as it's no longer necessary there.
    var lib: String { AmplifyAWSServiceConfiguration.userAgentLib }

    public func send(request: SdkHttpRequest) async throws -> HttpResponse {
        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let userAgent = "\(existingUserAgent) \(lib)"
        let updatedRequest = request.updatingUserAgent(with: userAgent)

        return try await target.send(request: updatedRequest)
    }
}

@_spi(PluginHTTPClientEngine)
extension HTTPClient where Self == UserAgentSettingClientEngine {
    public static func userAgentEngine(
        for configuration: AWSClientConfiguration<some AWSServiceSpecificConfiguration>
    ) -> Self {
        let baseClientEngine = baseClientEngine(for: configuration)
        return self.init(target: baseClientEngine)
    }
}
