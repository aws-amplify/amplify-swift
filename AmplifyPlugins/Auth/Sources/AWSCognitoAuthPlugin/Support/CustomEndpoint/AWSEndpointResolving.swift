//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSClientRuntime
import ClientRuntime
import AWSCognitoIdentityProvider

struct AWSEndpointResolving: AWSCognitoIdentityProvider.EndpointResolver {
    func resolve(params: AWSCognitoIdentityProvider.EndpointParams) throws -> ClientRuntime.Endpoint {
        try endpoint()
    }

    let endpoint: () throws -> ClientRuntime.Endpoint

    init(_ endpoint: @escaping () throws -> ClientRuntime.Endpoint) {
        self.endpoint = endpoint
    }

    init(_ endpoint: @escaping @autoclosure () throws -> ClientRuntime.Endpoint) {
        self.endpoint = endpoint
    }
}
