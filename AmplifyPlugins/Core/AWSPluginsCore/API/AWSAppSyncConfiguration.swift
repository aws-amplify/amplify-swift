//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) import Amplify

public struct AWSAppSyncConfiguration {
    public let region: String
    public let endpoint: URL
    public let apiKey: String?

    public init(with amplifyOutputs: AmplifyOutputs) throws {
        let resolvedConfiguration = try amplifyOutputs.resolveConfiguration()

        guard let dataCategory = resolvedConfiguration.data else {
            throw ConfigurationError.invalidAmplifyOutputsFile(
                "Missing data category", "", nil)
        }

        self.region = dataCategory.awsRegion
        guard let endpoint = URL(string: dataCategory.url) else {
            throw ConfigurationError.invalidAmplifyOutputsFile(
                "Missing region from data category", "", nil)
        }
        self.endpoint = endpoint
        self.apiKey = dataCategory.apiKey

    }
}
