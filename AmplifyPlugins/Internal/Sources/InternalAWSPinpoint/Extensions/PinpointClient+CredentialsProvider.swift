//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import AWSPinpoint
@_spi(FoundationClientEngine) import AWSPluginsCore

extension PinpointClient {
    convenience init(region: String, credentialsProvider: CredentialsProvider) throws {
        let configuration = try PinpointClientConfiguration(
            credentialsProvider: credentialsProvider,
            frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData(),
            region: region
        )
        #if os(iOS) || os(macOS) // no-op
        #else
        // For any platform except iOS or macOS
        // Use Foundation instead of CRT for networking.
        configuration.httpClientEngine = FoundationClientEngine()
        #endif
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
