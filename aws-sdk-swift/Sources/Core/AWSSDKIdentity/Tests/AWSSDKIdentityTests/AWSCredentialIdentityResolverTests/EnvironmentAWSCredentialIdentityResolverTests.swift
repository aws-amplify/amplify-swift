//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct AWSSDKIdentity.EnvironmentAWSCredentialIdentityResolver

class EnvironmentAWSCredentialIdentityResolverTests: XCTestCase {
    func testGetCredentials() async throws {
        setenv("AWS_ACCESS_KEY_ID", "some_access_key_a", 1)
        setenv("AWS_SECRET_ACCESS_KEY", "some_secret_a", 1)

        defer {
            unsetenv("AWS_ACCESS_KEY_ID")
            unsetenv("AWS_SECRET_ACCESS_KEY")
        }

        let subject = try EnvironmentAWSCredentialIdentityResolver()
        let credentials = try await subject.getIdentity()
        
        XCTAssertEqual(credentials.accessKey, "some_access_key_a")
        XCTAssertEqual(credentials.secret, "some_secret_a")
    }
}
