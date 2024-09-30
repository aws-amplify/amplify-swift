//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct AWSSDKIdentity.ProfileAWSCredentialIdentityResolver
@_spi(FileBasedConfig) @testable import AWSClientRuntime

class ProfileAWSCredentialIdentityResolverTests: XCTestCase {
    let configPath = Bundle.module.path(forResource: "config", ofType: nil)!
    let configWithProcessPath = Bundle.module.path(forResource: "config_with_process", ofType: nil)!
    let credentialsPath = Bundle.module.path(forResource: "credentials", ofType: nil)!
    
    func testGetCredentialsWithDefaultProfile() async throws {
        let subject = try ProfileAWSCredentialIdentityResolver(
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
        )
        let credentials = try await subject.getIdentity()

        XCTAssertEqual(credentials.accessKey, "access_key_default_cred")
        XCTAssertEqual(credentials.secret, "secret_default_cred")
    }

    func testGetCredentialsWithDefaultProfileContainingProcess() async throws {
        let subject = try ProfileAWSCredentialIdentityResolver(
            configFilePath: configWithProcessPath,
            credentialsFilePath: credentialsPath
        )
        let credentials = try await subject.getIdentity()

        XCTAssertEqual(credentials.accessKey, "AccessKey123")
        XCTAssertEqual(credentials.secret, "SecretAccessKey123")
    }

    func testGetCredentialsWithNamedProfileFromConfigFile() async throws {
        let subject = try ProfileAWSCredentialIdentityResolver(
            profileName: "credentials-provider-config-tests-profile",
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
        )
        let credentials = try await subject.getIdentity()
        
        XCTAssertEqual(credentials.accessKey, "access_key_profile_config")
        XCTAssertEqual(credentials.secret, "secret_profile_config")
    }
    
    func testGetCredentialsWithNamedProfileFromCredentialsFile() async throws {
        let subject = try ProfileAWSCredentialIdentityResolver(
            profileName: "credentials-provider-creds-tests-profile",
            configFilePath: configPath,
            credentialsFilePath: credentialsPath
        )
        let credentials = try await subject.getIdentity()
        
        XCTAssertEqual(credentials.accessKey, "access_key_profile_cred")
        XCTAssertEqual(credentials.secret, "secret_profile_cred")
    }
}
