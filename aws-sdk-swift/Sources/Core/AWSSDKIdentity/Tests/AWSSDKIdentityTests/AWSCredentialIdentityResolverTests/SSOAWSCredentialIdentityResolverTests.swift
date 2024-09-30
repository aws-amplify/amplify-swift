//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct AWSSDKIdentity.SSOAWSCredentialIdentityResolver
@_spi(FileBasedConfig) @testable import AWSClientRuntime

class SSOAWSCredentialIdentityResolverTests: XCTestCase {
    let configPath = Bundle.module.path(forResource: "sso_tests", ofType: nil)!
    let credentialsPath = Bundle.module.path(forResource: "credentials", ofType: nil)!
    
    func testCreateSSOAWSCredentialIdentityResolverNonexistentProfile() async throws {
        XCTAssertThrowsError(try SSOAWSCredentialIdentityResolver(
            profileName: "PROFILE_NOT_IN_SSO_TESTS_CONFIG_FILE",
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
            )
        )
    }
    
    func testCreateSSOAWSCredentialIdentityResolverLegacyProfile() async throws {
        _ = try SSOAWSCredentialIdentityResolver(
            profileName: "user",
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
        )
        // SUCCESS: creation didn't throw error
    }
    
    func testCreateSSOAWSCredentialIdentityResolverTokenProviderProfile() async throws {
        _ = try SSOAWSCredentialIdentityResolver(
            profileName: "dev",
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
        )
        // SUCCESS: creation didn't throw error
    }
}
