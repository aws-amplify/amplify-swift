//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import protocol AWSClientRuntime.Environment
import struct AWSSDKIdentity.ECSAWSCredentialIdentityResolver

class ECSAWSCredentialIdentityResolverTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // Unset the environment variables before each test
        unsetenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        unsetenv("AWS_CONTAINER_CREDENTIALS_FULL_URI")
        unsetenv("AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE")
        unsetenv("AWS_CONTAINER_AUTHORIZATION_TOKEN")
    }

    override func tearDown() {
        // Unset the environment variables after each test
        unsetenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        unsetenv("AWS_CONTAINER_CREDENTIALS_FULL_URI")
        unsetenv("AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE")
        unsetenv("AWS_CONTAINER_AUTHORIZATION_TOKEN")

        super.tearDown()
    }

    func testGetCredentialsWithRelativeURI() async throws {
        // relative uri is preferred over absolute uri so we shouldn't get thrown an error
        let resolver = try ECSAWSCredentialIdentityResolver(
            relativeURI: "/subfolder/test.txt",
            absoluteURI: "invalid absolute uri"
        )
        XCTAssertEqual(resolver.resolvedHost, "169.254.170.2")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithAbsoluteURI() async throws {
        let resolver = try ECSAWSCredentialIdentityResolver(
            relativeURI: nil,
            absoluteURI: "http://www.example.com/subfolder/test.txt"
        )
        XCTAssertEqual(resolver.resolvedHost, "www.example.com")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithInvalidAbsoluteURI() async throws {
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver(relativeURI: nil, absoluteURI: "test"))
    }

    func testGetCredentialsWithMissingURI() async throws {
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver(relativeURI: nil, absoluteURI: nil))
    }

    func testGetCredentialsWithRelativeURIEnv() async throws {
        // relative uri is preferred over absolute uri so we shouldn't get thrown an error
        setenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI", "/subfolder/test.txt", 1)
        let resolver = try ECSAWSCredentialIdentityResolver()
        XCTAssertEqual(resolver.resolvedHost, "169.254.170.2")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithAbsoluteURIEnv() async throws {
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "http://www.example.com/subfolder/test.txt", 1)
        let resolver = try ECSAWSCredentialIdentityResolver()
        XCTAssertEqual(resolver.resolvedHost, "www.example.com")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithInvalidAbsoluteURIEnv() async throws {
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "test", 1)
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver())
    }

    func testGetCredentialsWithMissingURIEnv() async throws {
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver())
    }

    func testGetCredentialsWithTokenFile() async throws {
        // Simulating a token file

        let tokenFilePath = Bundle.module.url(forResource: "test_token", withExtension: "txt")!.path

        // Set the environment variable to point to the token file
        setenv("AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE", tokenFilePath, 1)
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "http://www.example.com/subfolder/test.txt", 1)

        // Ensure the resolver correctly loads the token from the file
        let resolver = try ECSAWSCredentialIdentityResolver()
        XCTAssertEqual(resolver.resolvedAuthorizationToken, "sample-token")
        XCTAssertEqual(resolver.resolvedHost, "www.example.com")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithTokenEnv() async throws {
        // Set the environment variable directly for the token
        setenv("AWS_CONTAINER_AUTHORIZATION_TOKEN", "env-token", 1)
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "http://www.example.com/subfolder/test.txt", 1)

        // Ensure the resolver correctly loads the token from the environment
        let resolver = try ECSAWSCredentialIdentityResolver()
        XCTAssertEqual(resolver.resolvedAuthorizationToken, "env-token")
        XCTAssertEqual(resolver.resolvedHost, "www.example.com")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testGetCredentialsWithDirectToken() async throws {
        // Pass the token directly to the resolver
        let resolver = try ECSAWSCredentialIdentityResolver(
            absoluteURI: "http://www.example.com/subfolder/test.txt",
            authorizationToken: "direct-token"
        )

        // Ensure the resolver correctly uses the passed token
        XCTAssertEqual(resolver.resolvedAuthorizationToken, "direct-token")
        XCTAssertEqual(resolver.resolvedHost, "www.example.com")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/subfolder/test.txt")
    }

    func testTokenNotResolvedWithRelativeURI() async throws {
        // Pass the token directly to the resolver
        let resolver = try ECSAWSCredentialIdentityResolver(
            relativeURI: "/test",
            authorizationToken: "direct-token"
        )

        // Ensure the resolver correctly uses the passed token
        // Authorization token is not used with relative URI
        XCTAssertEqual(resolver.resolvedAuthorizationToken, nil)
        XCTAssertEqual(resolver.resolvedHost, "169.254.170.2")
        XCTAssertEqual(resolver.resolvedPathAndQuery, "/test")
    }
}
