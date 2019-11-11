//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {
    func add(interceptor: URLRequestInterceptor, for apiName: String) throws {
        let endpointOptional = pluginConfig.endpoints[apiName]

        guard var endpoint = endpointOptional else {
            throw PluginError.pluginConfigurationError("Failed to get endpoint configuration for apiName: \(apiName)",
                                                       "")
        }

        endpoint.addInterceptor(interceptor: interceptor)
    }
}
