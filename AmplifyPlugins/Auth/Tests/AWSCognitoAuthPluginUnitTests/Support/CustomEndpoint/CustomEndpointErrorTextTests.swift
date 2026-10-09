//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The exact text of the configuration error an invalid custom `Endpoint` produces. The error catalogue
/// does not cover these three errors, so this pins them across the validation's move into the engine.
final class CustomEndpointErrorTextTests: XCTestCase {

    /// An invalid endpoint, with the validation step it fails and the recovery suggestion it gets.
    struct InvalidEndpoint {
        let input: String
        let step: String
        let recoverySuggestion: String
    }

    static let invalidEndpoints: [InvalidEndpoint] = [
        InvalidEndpoint(
            input: "https://foo.com",
            step: "schemeIsEmpty",
            recoverySuggestion: """
            Invalid scheme for value `endpoint`: https://foo.com.
            AWSCognitoAuthPlugin only supports the https scheme.
            > Remove the scheme in your `endpoint` value.
            e.g.
            "endpoint": foo.com
            """
        ),
        InvalidEndpoint(
            input: "\\",
            step: "validURL",
            recoverySuggestion: """
            Invalid value for `endpoint`: \\
            Expected valid url, received: \\
            > Replace \\ with a valid URL.
            """
        ),
        InvalidEndpoint(
            input: "foo.com/hello/world",
            step: "pathIsEmpty",
            recoverySuggestion: """
            Invalid value for `endpoint`: foo.com/hello/world.
            Expected empty path, received path value: /hello/world for endpoint: foo.com/hello/world.
            > Remove the path value from your endpoint.
            """
        )
    ]

    static let errorDescription = "Error configuring AWSCognitoAuthPlugin"

    /// Test that configuring with an invalid custom endpoint throws the public error, with its text
    ///
    /// - Given: A Gen1 `awsCognitoAuthPlugin` configuration whose `Endpoint` fails each validation step
    /// - When:
    ///    - `ConfigurationHelper.parseUserPoolData(_:)` reads it
    /// - Then:
    ///    - It throws an `AuthError.configuration` (not an engine error) with the recorded description and
    ///      recovery suggestion, and no underlying error
    ///
    func testInvalidEndpointThrowsThePublicErrorText() throws {
        for invalid in Self.invalidEndpoints {
            let (input, step, recoverySuggestion) = (invalid.input, invalid.step, invalid.recoverySuggestion)
            let configuration = try Self.configuration(endpoint: input)
            XCTAssertThrowsError(try ConfigurationHelper.parseUserPoolData(configuration), step) { error in
                guard case .configuration(let description, let suggestion, let underlying) = error as? AuthError else {
                    return XCTFail("\(step): expected AuthError.configuration, got \(type(of: error)): \(error)")
                }
                XCTAssertEqual(description, Self.errorDescription, step)
                XCTAssertEqual(suggestion, recoverySuggestion, step)
                XCTAssertNil(underlying, step)
            }
        }
    }

    /// Test that the engine's endpoint validation throws its own error, with the same text
    ///
    /// - Given: Each invalid endpoint
    /// - When:
    ///    - `EndpointResolving.userPool` validates it
    /// - Then:
    ///    - It throws an `EngineAuthError.configuration` with the description and recovery suggestion the
    ///      public error has, and no underlying error
    ///
    func testEngineValidationThrowsTheSameText() {
        for invalid in Self.invalidEndpoints {
            let (input, step, recoverySuggestion) = (invalid.input, invalid.step, invalid.recoverySuggestion)
            XCTAssertThrowsError(try EndpointResolving.userPool.run(input), step) { error in
                guard case .configuration(let description, let suggestion, let underlying) = error as? EngineAuthError
                else {
                    return XCTFail("\(step): expected EngineAuthError.configuration, got \(type(of: error)): \(error)")
                }
                XCTAssertEqual(description, Self.errorDescription, step)
                XCTAssertEqual(suggestion, recoverySuggestion, step)
                XCTAssertNil(underlying, step)
            }
        }
    }

    /// A Gen1 configuration with a user pool whose `Endpoint` is `endpoint`.
    static func configuration(endpoint: String) throws -> JSONValue {
        let object: [String: Any] = [
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_Pool",
                    "AppClientId": "client",
                    "Region": "us-east-1",
                    "Endpoint": endpoint
                ]
            ]
        ]
        return try JSONDecoder().decode(JSONValue.self, from: JSONSerialization.data(withJSONObject: object))
    }
}
