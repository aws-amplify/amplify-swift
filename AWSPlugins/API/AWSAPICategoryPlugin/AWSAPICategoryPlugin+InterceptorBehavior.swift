//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {
    func add(interceptor: URLRequestInterceptor, for apiName: String) {
        // Need to get the EndpointConfig for this apiName, then invoke
        // endpointConfig.addInterceptor(interceptor)
        fatalError("Not yet implemented")
    }
}
