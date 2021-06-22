//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPIPlugin {
    func add(interceptor: URLRequestInterceptor, for apiName: String) throws {
        guard pluginConfig.endpoints[apiName] != nil else {
            throw PluginError.pluginConfigurationError("Failed to get endpoint configuration for apiName: \(apiName)",
                                                       "")
        }

        pluginConfig.addInterceptor(interceptor, toEndpoint: apiName)
    }
}
