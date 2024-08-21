//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) import Amplify


/// Hold necessary AWS AppSync configuration values to interact with the AppSync API
public struct AWSAppSyncConfiguration {
    
    /// The region of the AWS AppSync API
    public let region: String

    /// The endpoint of the AWS AppSync API
    public let endpoint: URL

    /// API key for API Key authentication.
    public let apiKey: String?


    /// Initializes an `AWSAppSyncConfiguration` instance using the provided AmplifyOutputs file.
    /// AmplifyOutputs support multiple ways to read the `amplify_outputs.json` configuration file
    ///
    /// For example, `try AWSAppSyncConfiguraton(with: .amplifyOutputs)` will read the
    /// `amplify_outputs.json` file from the main bundle.
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
