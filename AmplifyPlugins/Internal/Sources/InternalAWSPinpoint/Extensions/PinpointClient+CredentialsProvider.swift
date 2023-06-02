//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import AWSPluginsCore
import AWSPinpoint

extension PinpointClient {
    convenience init(region: String, credentialsProvider: CredentialsProviding) throws {
        let configuration = try PinpointClientConfiguration(
            region: region,
            credentialsProvider: credentialsProvider,
            frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData()
        )
        PinpointRequestsRegistry.shared.setCustomHttpEngine(on: configuration)
        self.init(config: configuration)
    }
}
