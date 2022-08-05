//
//  EndpointResolvingTestCase.swift
//  
//
//  Created by Saultz, Ian on 8/5/22.
//

import XCTest
@testable import AWSCognitoAuthPlugin
import Amplify

class EndpointResolvingTestCase: XCTestCase {
    func testUserPool_Valid() throws {
        let validInput = "foo.com"
        let endpoint = try EndpointResolving.userPool.run(validInput)
        XCTAssertEqual(endpoint.host, "foo.com")
        XCTAssertEqual(endpoint.path, "/")
    }

    func testUserPool_Invalid() throws {
        do { // fail schemeIsEmpty()
            let invalidInput = "https://foo.com"
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
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

        do { // fail validURL()
            let invalidInput = "\\"
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
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

        do { // fail pathIsEmpty()
            let path = "/hello/world"
            let invalidInput = "foo.com" + path
            XCTAssertThrowsError(
                try EndpointResolving.userPool.run(invalidInput),
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
                    Expected empty path, received path value: \(path) for endpoint: \(invalidInput).
                    > Remove the path value from your endpoint.
                    """
                )
            }
        }
    }
}
