//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import AWSCognitoIdentity

struct AWSEndpointResolving: AWSCognitoIdentity.EndpointResolver {
    func resolve(params: AWSCognitoIdentity.EndpointParams) throws -> ClientRuntime.Endpoint {
        try endpoint()
    }

    let endpoint: () throws -> ClientRuntime.Endpoint

    init(_ endpoint: @escaping () throws -> ClientRuntime.Endpoint) {
        self.endpoint = endpoint
    }

    init(_ endpoint: @escaping @autoclosure () throws -> ClientRuntime.Endpoint) {
        self.endpoint = endpoint
    }

//    func resolve(serviceId: String, region: String) throws -> AWSEndpoint {
//        let endpoint = try endpoint()
//        return AWSEndpoint.init(endpoint: endpoint)
//    }
}
