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
    public let target: HttpClientEngine
    private let userAgentKey = "User-Agent"

    public init(target: HttpClientEngine) {
        self.target = target
    }
}

@_spi(PluginHTTPClientEngine)
extension UserAgentSettingClientEngine: HttpClientEngine {
    // CI updates the `platformName` property in `AmplifyAWSServiceConfiguration`. 
    // We can / probably should move this in the future
    // as it's no longer necessary there.
    var lib: String { AmplifyAWSServiceConfiguration.userAgentLib }

    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        let existingUserAgent = request.headers.value(for: userAgentKey) ?? ""
        let userAgent = "\(existingUserAgent) \(lib)"
        let updatedRequest = request.updatingUserAgent(with: userAgent)

        return try await target.execute(request: updatedRequest)
    }
}

@_spi(PluginHTTPClientEngine)
extension HttpClientEngine where Self == UserAgentSettingClientEngine {
    public static func userAgentEngine(
        for configuration: AWSClientConfiguration<some AWSServiceSpecificConfiguration>
    ) -> Self {
        let baseClientEngine = baseClientEngine(for: configuration)
        return self.init(target: baseClientEngine)
    }
}
