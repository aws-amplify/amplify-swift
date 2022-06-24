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
    convenience init(region: String, credentialsProvider: CredentialsProvider) throws {
        let configuration = try PinpointClientConfiguration(
            region: region,
            credentialsProvider: credentialsProvider,
            frameworkMetadata: AmplifyAWSServiceConfiguration.frameworkMetaData()
        )

        self.init(config: configuration)
    }
}
