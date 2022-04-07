//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct APIKeyURLRequestInterceptor: URLRequestInterceptor {

    let apiKeyProvider: APIKeyProvider

    init(apiKeyProvider: APIKeyProvider) {
        self.apiKeyProvider = apiKeyProvider
    }

    func intercept(_ request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        let apiKey = apiKeyProvider.getAPIKey()
        modifiedRequest.addValue(apiKey,
                                 forHTTPHeaderField: URLRequestConstants.Header.xApiKey)
        modifiedRequest.setValue(AWSAPIPluginsCore.baseUserAgent(),
                                 forHTTPHeaderField: URLRequestConstants.Header.userAgent)

        return modifiedRequest
    }

    // MARK: - Utilities

    private static func apiKey(from endpointJSON: [String: JSONValue]) throws -> String {
        guard case .string(let apiKey) = endpointJSON["apiKey"] else {
            throw PluginError.pluginConfigurationError(
                "Could not get `ApiKey` from plugin configuration",
                """
                The specified configuration does not have a string with the key `apiKey`. Review the \
                configuration and ensure it contains the expected values:
                \(endpointJSON)
                """
            )
        }

        return apiKey
    }

}
