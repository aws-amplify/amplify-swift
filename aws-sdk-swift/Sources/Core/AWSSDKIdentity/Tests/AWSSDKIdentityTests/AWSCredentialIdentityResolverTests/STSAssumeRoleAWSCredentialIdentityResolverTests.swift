//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct AWSSDKIdentity.STSAssumeRoleAWSCredentialIdentityResolver
import struct AWSSDKIdentity.EnvironmentAWSCredentialIdentityResolver
import enum Smithy.ClientError

class STSAssumeRoleAWSCredentialIdentityResolverTests: XCTestCase {
    func testInit() {
        // For now we'll lean on CRT to test the implementation of this provider
        // so just assert that we created the provider without crashing.
        // Note: The underlying CRT provider throws an error if the role is invalid,
        // so we'll assert that is the case here since mocking out a valid STS Assume Role is out scope for now.
        // TODO: Add an integration test for this provider
        XCTAssertThrowsError(try STSAssumeRoleAWSCredentialIdentityResolver(
            awsCredentialIdentityResolver: try EnvironmentAWSCredentialIdentityResolver(),
            roleArn: "invalid-role",
            sessionName: "some-session"
        ))
    }

    func testInvalidSessionName() async throws {
        XCTAssertThrowsError(try STSAssumeRoleAWSCredentialIdentityResolver(
                awsCredentialIdentityResolver: try EnvironmentAWSCredentialIdentityResolver(),
                roleArn: "role",
                sessionName: "invalid session name with spaces"
        )) { error in
            if case ClientError.invalidValue = error {
                // The test passes if this case is matched
            } else {
                XCTFail("Expected ClientError.invalidValue error, but got \(error)")
            }
        }
    }
}
