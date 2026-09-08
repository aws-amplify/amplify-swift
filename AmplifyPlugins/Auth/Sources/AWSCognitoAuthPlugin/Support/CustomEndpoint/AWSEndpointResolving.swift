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

    // `@Sendable` so this resolver can satisfy the AWS SDK's `Sendable` requirement.
    let endpoint: @Sendable () throws -> SmithyHTTPAPI.Endpoint

    init(_ endpoint: @escaping @Sendable () throws -> SmithyHTTPAPI.Endpoint) {
        self.endpoint = endpoint
    }

    init(_ endpoint: @escaping @autoclosure @Sendable () throws -> SmithyHTTPAPI.Endpoint) {
        self.endpoint = endpoint
    }
}
