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
                "",
                AuthError.validateConfigurationError
            )
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
            "",
            AuthError.validateConfigurationError
        )
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
            "",
            AuthError.validateConfigurationError
        )
    }
}
