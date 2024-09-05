//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import AWSPinpoint
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
import SmithyIdentity

extension PinpointClient {
    convenience init(region: String, credentialIdentityResolver: some AWSCredentialIdentityResolver) throws {
        // TODO: FrameworkMetadata Replacement
        let configuration = try PinpointClientConfiguration(
            awsCredentialIdentityResolver: credentialIdentityResolver,
            region: region,
            signingRegion: region
        )

        configuration.httpClientEngine = .userAgentEngine(for: configuration)
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
