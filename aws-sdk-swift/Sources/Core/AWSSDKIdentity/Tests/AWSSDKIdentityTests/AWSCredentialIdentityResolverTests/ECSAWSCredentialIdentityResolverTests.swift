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
    func testGetCredentialsWithRelativeURI() async throws {
        // relative uri is preferred over absolute uri so we shouldn't get thrown an error
        XCTAssertNoThrow(try ECSAWSCredentialIdentityResolver(relativeURI: "subfolder/test.txt", absoluteURI: "invalid absolute uri"))
    }

    func testGetCredentialsWithAbsoluteURI() async throws {
        XCTAssertNoThrow(try ECSAWSCredentialIdentityResolver(relativeURI: nil, absoluteURI: "http://www.example.com/subfolder/test.txt"))
    }

    func testGetCredentialsWithInvalidAbsoluteURI() async throws {
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver(relativeURI: nil, absoluteURI: "test"))
    }

    func testGetCredentialsWithMissingURI() async throws {
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver(relativeURI: nil, absoluteURI: nil))
    }

    func testGetCredentialsWithRelativeURIEnv() async throws {
        // relative uri is preferred over absolute uri so we shouldn't get thrown an error
        setenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI", "subfolder/test.txt", 1)
        unsetenv("AWS_CONTAINER_CREDENTIALS_FULL_URI")
        XCTAssertNoThrow(try ECSAWSCredentialIdentityResolver())
    }

    func testGetCredentialsWithAbsoluteURIEnv() async throws {
        unsetenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "http://www.example.com/subfolder/test.txt", 1)
        XCTAssertNoThrow(try ECSAWSCredentialIdentityResolver())
    }

    func testGetCredentialsWithInvalidAbsoluteURIEnv() async throws {
        unsetenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        setenv("AWS_CONTAINER_CREDENTIALS_FULL_URI", "test", 1)
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver())
    }

    func testGetCredentialsWithMissingURIEnv() async throws {
        unsetenv("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI")
        unsetenv("AWS_CONTAINER_CREDENTIALS_FULL_URI")
        XCTAssertThrowsError(try ECSAWSCredentialIdentityResolver())
    }
}

protocol EnvironmentProvider {
    func environmentVariable(key: String) -> String?
}

class MockEnvironment: Environment, EnvironmentProvider {
    let relativeURI: String?
    let absoluteURI: String?

    init(
        relativeURI: String? = nil,
        absoluteURI: String? = nil
    ) {
        self.relativeURI = relativeURI
        self.absoluteURI = absoluteURI
    }

    func environmentVariable(key: String) -> String? {
        switch key {
        case "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI":
            return self.relativeURI
        case "AWS_CONTAINER_CREDENTIALS_FULL_URI":
            return self.absoluteURI
        default:
            return nil
        }
    }
}
