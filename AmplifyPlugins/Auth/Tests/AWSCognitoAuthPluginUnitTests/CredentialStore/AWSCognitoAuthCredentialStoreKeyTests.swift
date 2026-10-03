//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// Pins the keychain keys under which device records are stored. Existing users' device records live
/// under these exact keys, so any change to them orphans those records.
class AWSCognitoAuthCredentialStoreKeyTests: XCTestCase {

    private let username = "MixedCase.User@Example.com"

    private let userPool = UserPoolConfigurationData(
        poolId: "us-east-1_Pool",
        clientId: "client",
        region: "us-east-1"
    )

    private let identityPool = IdentityPoolConfigurationData(
        poolId: "us-east-1:identity-pool",
        region: "us-east-1"
    )

    /// Test that the device metadata key is unchanged, including the lowercasing of the username
    ///
    /// - Given: A credential store for each kind of auth configuration
    /// - When:
    ///    - The device metadata key is generated for a mixed-case username
    /// - Then:
    ///    - The key is exactly `amplify.<pool ids>.<lowercased username>.deviceMetadata`
    ///
    func testGenerateDeviceMetadataKey_isUnchanged() {
        XCTAssertEqual(
            makeStore(.userPools(userPool)).generateDeviceMetadataKey(for: username),
            "amplify.us-east-1_Pool.mixedcase.user@example.com.deviceMetadata"
        )
        XCTAssertEqual(
            makeStore(.userPoolsAndIdentityPools(userPool, identityPool)).generateDeviceMetadataKey(for: username),
            "amplify.us-east-1_Pool.us-east-1:identity-pool.mixedcase.user@example.com.deviceMetadata"
        )
        XCTAssertEqual(
            makeStore(.identityPools(identityPool)).generateDeviceMetadataKey(for: username),
            "amplify.us-east-1:identity-pool.mixedcase.user@example.com.deviceMetadata"
        )
    }

    /// Test that the ASF device key is unchanged, including keeping the username's case
    ///
    /// - Given: A credential store for each kind of auth configuration
    /// - When:
    ///    - The ASF device key is generated for a mixed-case username
    /// - Then:
    ///    - The key is exactly `amplify.<pool ids>.<username as given>.deviceASF`
    ///
    func testGenerateASFDeviceKey_isUnchanged() {
        XCTAssertEqual(
            makeStore(.userPools(userPool)).generateASFDeviceKey(for: username),
            "amplify.us-east-1_Pool.MixedCase.User@Example.com.deviceASF"
        )
        XCTAssertEqual(
            makeStore(.userPoolsAndIdentityPools(userPool, identityPool)).generateASFDeviceKey(for: username),
            "amplify.us-east-1_Pool.us-east-1:identity-pool.MixedCase.User@Example.com.deviceASF"
        )
        XCTAssertEqual(
            makeStore(.identityPools(identityPool)).generateASFDeviceKey(for: username),
            "amplify.us-east-1:identity-pool.MixedCase.User@Example.com.deviceASF"
        )
    }

    private func makeStore(_ authConfiguration: AuthConfiguration) -> AWSCognitoAuthCredentialStore {
        AWSCognitoAuthCredentialStore(authConfiguration: authConfiguration, logger: AmplifyEngineLogRouter())
    }
}
