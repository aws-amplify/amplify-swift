//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package extension EndpointResolving {
    struct ValidationStep<Input, Output> {
        package let validate: (Input) throws -> Output
    }
}

// MARK: Custom Endpoint validation steps.
package extension EndpointResolving.ValidationStep {
    /// Validate that the input string doesn't contain a scheme.
    static func schemeIsEmpty() -> Self where Input == String, Output == Void {
        .init { endpoint in
            let scheme = URLComponents(string: endpoint)?.scheme
            guard scheme.map(\.isEmpty) ?? true else {
                throw EngineAuthError.invalidScheme(endpoint)
            }
        }
    }

    /// Validate that the input string forms a valid URL when prepending `https://` as the scheme.
    static func validURL() -> Self where Input == String, Output == (URLComponents, String) {
        .init { endpoint in
            guard
                let components = URLComponents(string: "https://\(endpoint)"),
                components.url != nil,
                let host = components.host,
                !host.isEmpty
            else {
                throw EngineAuthError.invalidURL(endpoint)
            }
            return (components, host)
        }
    }

    /// Validate that the input `URLComponents` don't contain a path.
    static func pathIsEmpty() -> Self where Input == (URLComponents, String), Output == Void {
        .init { components, endpoint in
            guard components.path.isEmpty else {
                throw EngineAuthError.invalidPath(
                    endpoint: endpoint,
                    components: components
                )
            }
        }
    }
}

// MARK: Fileprivate EngineAuthError extensions thrown on invalid `Endpoint` input. `ConfigurationHelper`
// rethrows them as the `AuthError` of the same case and text.
private extension EngineAuthError {
    static func invalidURL(_ endpoint: String) -> EngineAuthError {
        .configuration(
            "Error configuring AWSCognitoAuthPlugin",
            """
            Invalid value for `endpoint`: \(endpoint)
            Expected valid url, received: \(endpoint)
            > Replace \(endpoint) with a valid URL.
            """
        )
    }

    static func invalidScheme(_ endpoint: String) -> EngineAuthError {
        .configuration(
            "Error configuring AWSCognitoAuthPlugin",
            """
            Invalid scheme for value `endpoint`: \(endpoint).
            AWSCognitoAuthPlugin only supports the https scheme.
            > Remove the scheme in your `endpoint` value.
            e.g.
            "endpoint": \(URL(string: endpoint)?.host ?? "example.com")
            """
        )
    }

    static func invalidPath(
        endpoint: String,
        components: URLComponents
    ) -> EngineAuthError {
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
