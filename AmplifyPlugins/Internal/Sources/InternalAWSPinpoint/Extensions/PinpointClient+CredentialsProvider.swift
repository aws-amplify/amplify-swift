//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import AWSPinpoint
@_spi(FoundationHTTPClientEngine) import AWSPluginsCore

extension PinpointClient {
    convenience init(region: String, credentialsProvider: CredentialsProvider) throws {
        let configuration = try PinpointClientConfiguration(
            credentialsProvider: credentialsProvider,
            frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
            region: region
        )
        #if os(watchOS) || os(tvOS)
        // Use Foundation instead of CRT for networking on watchOS and tvOS
        configuration.httpClientEngine = FoundationHTTPClient()
        #endif
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
