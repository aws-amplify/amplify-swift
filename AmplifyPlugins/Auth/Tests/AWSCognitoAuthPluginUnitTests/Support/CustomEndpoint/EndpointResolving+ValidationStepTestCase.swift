//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import Amplify

class EndpointResolving_ValidationStepTestCase: XCTestCase {
    // MARK: EndpointResolving.ValidationStep.schemeIsEmpty()
    /// Given: A String representation of a URL.
    /// When: That String doesn't contain a scheme.
    /// Then: ValidationStep should not throw.
    func testSchemeIsEmpty_Valid() throws {
        let validInput = "foo.com"
        XCTAssertNoThrow(
            try EndpointResolving.ValidationStep.schemeIsEmpty()
                .validate(validInput)
        )
    }

    func testSchemeIsEmpty_Invalid() throws {
        /// Given: A String representation of a URL.
        /// When: That String contains a scheme.
        /// Then: ValidationStep should throw an error.
        do {
            let invalidInput = "https://foo.com"
            XCTAssertThrowsError(
                try EndpointResolving.ValidationStep.schemeIsEmpty()
                    .validate(invalidInput)
            )
        }

        /// Given: A String representation of a URL.
        /// When: That String contains a scheme.
        /// Then: ValidationStep should throw an error with expected output.
        do {
            let invalidInput = "ws://foo.com"
            XCTAssertThrowsError(
                try EndpointResolving.ValidationStep.schemeIsEmpty()
                    .validate(invalidInput),
                ""
            ) { error in
                let e = error as? AuthError
                XCTAssertEqual(
                    e?.errorDescription,
                    "Error configuring AWSCognitoAuthPlugin"
                )
                XCTAssertEqual(
                    e?.recoverySuggestion,
                    """
                    Invalid scheme for value `endpoint`: \(invalidInput).
                    AWSCognitoAuthPlugin only supports the https scheme.
                    > Remove the scheme in your `endpoint` value.
                    e.g.
                    "endpoint": \(URL(string: invalidInput)?.host ?? "example.com")
                    """
                )
            }
        }
    }

    // MARK: EndpointResolving.ValidationStep.validURL()
    /// Given: A String representation of a URL.
    /// When: That String contains a valid URL.
    /// Then: ValidationStep should not throw.
    func testValidURL_Valid() throws {
        let validInput = "foo.com"
        XCTAssertNoThrow(
            try EndpointResolving.ValidationStep.validURL()
                .validate(validInput)
        )
    }

    /// Given: A String representation of a URL.
    /// When: That String contains an invalid URL.
    /// Then: ValidationStep should throw an error with expected output.
    func testValidURL_Invalid() throws {
        let invalidInput = "\\"
        XCTAssertThrowsError(
            try EndpointResolving.ValidationStep.validURL()
                .validate(invalidInput),
            ""
        ) { error in
            let e = error as? AuthError
            XCTAssertEqual(
                e?.errorDescription,
                "Error configuring AWSCognitoAuthPlugin"
            )
            XCTAssertEqual(
                e?.recoverySuggestion,
                """
                Invalid value for `endpoint`: \(invalidInput)
                Expected valid url, received: \(invalidInput)
                > Replace \(invalidInput) with a valid URL.
                """
            )
        }
    }

    // MARK: EndpointResolving.ValidationStep.pathIsEmpty()
    /// Given: A String representation of a URL.
    /// When: That String doesn't contain a path.
    /// Then: ValidationStep should not throw.
    func testPathIsEmpty_Valid() throws {
        let validInput = "https://foo.com"
        let components = URLComponents(string: validInput)!

        XCTAssertNoThrow(
            try EndpointResolving.ValidationStep.pathIsEmpty()
                .validate((components, validInput))
        )
    }

    /// Given: A String representation of a URL.
    /// When: That String contains a path.
    /// Then: ValidationStep should throw an error with expected output.
    func testPathIsEmpty_Invalid() throws {
        let invalidInput = "https://foo.com/hello"
        let components = URLComponents(string: invalidInput)!

        XCTAssertThrowsError(
            try EndpointResolving.ValidationStep.pathIsEmpty()
                .validate((components, invalidInput)),
            ""
        ) { error in
            let e = error as? AuthError
            XCTAssertEqual(
                e?.errorDescription,
                "Error configuring AWSCognitoAuthPlugin"
            )
            XCTAssertEqual(
                e?.recoverySuggestion,
                """
                Invalid value for `endpoint`: \(invalidInput).
                Expected empty path, received path value: \(components.path) for endpoint: \(invalidInput).
                > Remove the path value from your endpoint.
                """
            )
        }
    }
}
