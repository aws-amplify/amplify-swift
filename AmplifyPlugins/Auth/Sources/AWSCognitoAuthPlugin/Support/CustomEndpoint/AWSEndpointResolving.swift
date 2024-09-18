//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import SmithyHTTPAPI

struct AWSEndpointResolving: AWSCognitoIdentityProvider.EndpointResolver {
    func resolve(params: AWSCognitoIdentityProvider.EndpointParams) throws -> SmithyHTTPAPI.Endpoint {
        try endpoint()
    }

    let endpoint: () throws -> SmithyHTTPAPI.Endpoint

    init(_ endpoint: @escaping () throws -> SmithyHTTPAPI.Endpoint) {
        self.endpoint = endpoint
    }

    init(_ endpoint: @escaping @autoclosure () throws -> SmithyHTTPAPI.Endpoint) {
        self.endpoint = endpoint
    }
}
