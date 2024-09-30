//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct AWSSDKIdentity.SSOBearerTokenIdentityResolver
import func AWSSDKIdentity.loadTokenFile
import struct Smithy.Attributes
import XCTest

class SSOBearerTokenIdentityResolverTests: XCTestCase {
    let configPath = Bundle.module.path(forResource: "sso_tests", ofType: nil)!
    let expectedAccessToken = "ACCESS_TOKEN_STRING"

    func testLoadTokenFile() throws {
        // Load the test token file under Resources/
        let testTokenFileURL = Bundle.module.url(
            forResource: "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3", withExtension: "json"
        )
        let tokenString = try loadTokenFile(fileURL: testTokenFileURL!)
        XCTAssertEqual(expectedAccessToken, tokenString)
    }

    func testCreateSSOBearerTokenIdentityResolverLegacyProfile() async throws {
        _ = try SSOBearerTokenIdentityResolver(
            profileName: "user",
            configFilePath: configPath
        )
        // SUCCESS: creation didn't throw error
    }

    func testCreateSSOBearerTokenIdentityResolverTokenProviderProfile() async throws {
        _ = try SSOBearerTokenIdentityResolver(
            profileName: "dev",
            configFilePath: configPath
        )
        // SUCCESS: creation didn't throw error
    }
}
