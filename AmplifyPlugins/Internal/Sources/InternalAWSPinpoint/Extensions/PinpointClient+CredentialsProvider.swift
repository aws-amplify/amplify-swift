//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
@_spi(PluginHTTPClientEngine) import AWSPluginsCore

//extension PinpointClient {
//    convenience init(region: String, credentialsProvider: CredentialsProvider) throws {
//        // TODO: FrameworkMetadata Replacement
//        let configuration = try PinpointClientConfiguration(
//            region: region,
//            credentialsProvider: credentialsProvider
//        )
//
//        configuration.httpClientEngine = .userAgentEngine(for: configuration)
//        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
//        self.init(config: configuration)
//    }
//}
