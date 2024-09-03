//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPinpoint
import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials

extension PinpointClient {
    convenience init(region: String, credentialsProvider: CredentialsProviding) throws {
        // TODO: FrameworkMetadata Replacement
        let configuration = try PinpointClientConfiguration(
            region: region,
            credentialsProvider: credentialsProvider
        )

        configuration.httpClientEngine = .userAgentEngine(for: configuration)
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
