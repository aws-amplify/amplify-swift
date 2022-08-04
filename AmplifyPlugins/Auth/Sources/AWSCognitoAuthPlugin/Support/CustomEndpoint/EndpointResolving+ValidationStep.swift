//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension EndpointResolving {
    struct ValidationStep<Input, Output> {
        let validate: (Input) throws -> Output
    }
}

// MARK: Custom Endpoint validation steps.
extension EndpointResolving.ValidationStep {
    static func schemeIsEmpty() -> Self where Input == String, Output == Void {
        .init { endpoint in
            let scheme = URLComponents(string: endpoint)?.scheme
            guard scheme.map(\.isEmpty) ?? true else {
                throw AuthError.invalidScheme(endpoint)
            }
        }
    }
    
    static func validURL() -> Self where Input == String, Output == (URLComponents, String) {
        .init { endpoint in
            guard
                let components = URLComponents(string: "https://\(endpoint)"),
                components.url != nil,
                let host = components.host
            else {
                throw AuthError.invalidURL(endpoint)
            }
            return (components, host)
        }
    }
    
    static func pathIsEmpty() -> Self where Input == (URLComponents, String), Output == Void {
        .init { (components, endpoint) in
            guard components.path.isEmpty else {
                throw AuthError.invalidPath(
                    endpoint: endpoint,
                    components: components
                )
            }
        }
    }
}

// MARK: Fileprivate AuthError extensions thrown on invalid `Endpoint` input.
extension AuthError {
    fileprivate static func invalidURL(_ endpoint: String) -> AuthError {
        .configuration(
            "Error configuring AWSCognitoAuthPlugin",
            """
            Invalid value for `endpoint`: \(endpoint)
            Expected valid url, received: \(endpoint)
            > Replace \(endpoint) with a valid URL.
            """
        )
    }
    
    fileprivate static func invalidScheme(_ endpoint: String) -> AuthError {
        .configuration(
            "Error configuring AWSCognitoAuthPlugin",
            """
            Invalid scheme for value `endpoint`: \(endpoint).
            AWSCognitoAuthPlugin only supports the https scheme.
            > Remove the scheme in your `endpoint` value.
            e.g.
            "endpoint": "\(URL(string: endpoint)?.host ?? "foo.com")"
            """
        )
    }
    
    fileprivate static func invalidPath(
        endpoint: String,
        components: URLComponents
    ) -> AuthError {
        .configuration(
            "Error configuring AWSCognitoAuthPlugin",
            """
            Invalid value for `endpoint`: \(endpoint).
            Expected empty path, received path value: \(components.path) for endpoint: \(endpoint).
            > Remove the path value from your endpoint.
            """
        )
    }
}
