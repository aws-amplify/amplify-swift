//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {
    func add(interceptor: URLRequestInterceptor, for apiName: String) {
        let endpointOptional = pluginConfig.endpoints[apiName]

        guard let endpoint = endpointOptional else {
            fatalError("Failed to get endpoint configuration for apiName: \(apiName)")
        }

        endpoint.addInterceptor(interceptor: interceptor)
    }
}
