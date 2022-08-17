//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import Amplify

class EndpointResolvingTestCase: XCTestCase {
    /// Given: A String representation of a URL.
    /// When: That String satisfies the ValidationSteps `.schemeIsEmpty()`,
    /// `.validURL()`, and `.pathIsEmpty()` (in this order)
    /// Then: `EndpointResolving.userPool.run()` should not throw.
    func testUserPool_Valid() throws {
        let validInput = "foo.com"
        let endpoint = try EndpointResolving.userPool.run(validInput)
        XCTAssertEqual(endpoint.host, "foo.com")
        XCTAssertEqual(endpoint.path, "/")
    }

    func testUserPool_Invalid() throws {
        /// Given: A String representation of a URL.
        /// When: That String does not satisfy the ValidationStep `.schemeIsEmpty()`
        /// Then: `EndpointResolving.userPool.run()` should throw an error with expected output.
        do { // fail schemeIsEmpty()
            let invalidInput = "https://foo.com"
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
                "",
                AuthError.validateConfigurationError
            )
        }

        /// Given: A String representation of a URL.
        /// When: That String does not satisfy the ValidationStep `.validURL()`
        /// Then: `EndpointResolving.userPool.run()` should throw an error with expected output.
        do { // fail validURL()
            let invalidInput = "\\"
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
                "",
                AuthError.validateConfigurationError
            )
        }

        /// Given: A String representation of a URL.
        /// When: That String does not satisfy the ValidationStep `.pathIsEmpty()`
        /// Then: `EndpointResolving.userPool.run()` should throw an error with expected output.
        do { // fail pathIsEmpty()
            let path = "/hello/world"
            let invalidInput = "foo.com" + path
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
                "",
                AuthError.validateConfigurationError
            )
        }

        /// Given: A String representation of a URL.
        /// When: That String does not satisfy the ValidationStep `.validURL()`
        /// Then: `EndpointResolving.userPool.run()` should throw an error with expected output.
        do { // fail validURL()
            let invalidInput = ""
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
                "",
                AuthError.validateConfigurationError
            )
        }
    }
}
