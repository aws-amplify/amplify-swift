//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// import AWSClientRuntime
// import ClientRuntime
// import AWSCognitoIdentityProvider

struct AWSEndpointResolving: EndpointResolver {
    func resolve(params: EndpointParams) throws -> Endpoint {
        try endpoint()
    }

    let endpoint: () throws -> Endpoint

    init(_ endpoint: @escaping () throws -> Endpoint) {
        self.endpoint = endpoint
    }

    init(_ endpoint: @escaping @autoclosure () throws -> Endpoint) {
        self.endpoint = endpoint
    }
}

struct EndpointParams {
    /// Override the endpoint used to send this request
    let endpoint: Swift.String?
    /// The AWS region used to dispatch the request.
    let region: Swift.String?
    /// When true, use the dual-stack endpoint. If the configured endpoint does not support dual-stack, dispatching the request MAY return an error.
    let useDualStack: Swift.Bool
    /// When true, send this request to the FIPS-compliant regional endpoint. If the configured endpoint does not have a FIPS compliant endpoint, dispatching the request will return an error.
    let useFIPS: Swift.Bool

    init(
        endpoint: Swift.String? = nil,
        region: Swift.String? = nil,
        useDualStack: Swift.Bool = false,
        useFIPS: Swift.Bool = false
    )
    {
        self.endpoint = endpoint
        self.region = region
        self.useDualStack = useDualStack
        self.useFIPS = useFIPS
    }
}

protocol EndpointResolver {
    func resolve(params: EndpointParams) throws -> Endpoint
}
