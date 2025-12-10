//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(KeychainStore) import AWSPluginsCore
@testable import AWSCognitoAuthPlugin

class AWSCognitoAuthCredentialStoreTests: XCTestCase {

    private let userDefaultsNameSpace = "amplify_secure_storage_scopes.awsCognitoAuthPlugin"
    private var isKeychainConfiguredKey: String {
        "\(userDefaultsNameSpace).isKeychainConfigured"
    }

    override func setUp() {
        super.setUp()
        // Clean up UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: isKeychainConfiguredKey)
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: isKeychainConfiguredKey)
        super.tearDown()
    }

    /// Test that initialization is skipped when protected data is not available (simulating iOS prewarming)
    ///
    /// - Given: Protected data is not available (simulating iOS prewarming or device locked state)
    /// - When: AWSCognitoAuthCredentialStore is initialized
    /// - Then:
    ///    - The isKeychainConfigured flag should NOT be set in UserDefaults
    ///    - No keychain operations should be attempted
    @MainActor
    func testInitSkipsWhenProtectedDataUnavailable() {
        // Given: Simulate protected data unavailable (iOS prewarming scenario)
        let protectedDataAvailable = false

        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )

        // When: Initialize the credential store with mocked protected data check
        _ = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfig,
            accessGroup: nil,
            migrateKeychainItemsOfUserSession: false,
            isProtectedDataAvailable: { protectedDataAvailable }
        )

        // Then: The keychain configured flag should NOT be set
        let isConfigured = UserDefaults.standard.bool(forKey: isKeychainConfiguredKey)
        XCTAssertFalse(isConfigured, "isKeychainConfigured should not be set when protected data is unavailable")
    }

    /// Test that initialization proceeds normally when protected data is available
    ///
    /// - Given: Protected data is available (normal app launch)
    /// - When: AWSCognitoAuthCredentialStore is initialized
    /// - Then:
    ///    - The isKeychainConfigured flag should be set in UserDefaults
    @MainActor
    func testInitProceedsWhenProtectedDataAvailable() {
        // Given: Simulate protected data available (normal launch)
        let protectedDataAvailable = true

        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )

        // When: Initialize the credential store with mocked protected data check
        _ = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfig,
            accessGroup: nil,
            migrateKeychainItemsOfUserSession: false,
            isProtectedDataAvailable: { protectedDataAvailable }
        )

        // Then: The keychain configured flag should be set
        let isConfigured = UserDefaults.standard.bool(forKey: isKeychainConfiguredKey)
        XCTAssertTrue(isConfigured, "isKeychainConfigured should be set when protected data is available")
    }

    /// Test that credentials are preserved when protected data becomes unavailable during prewarming
    /// This simulates the Issue #3972 scenario where users were unexpectedly logged out
    ///
    /// - Given: A user has valid credentials stored and the app is prewarmed
    /// - When: AWSCognitoAuthCredentialStore is initialized during prewarming (protected data unavailable)
    /// - Then:
    ///    - The initialization should skip without clearing credentials
    ///    - The isKeychainConfigured flag should remain unchanged
    @MainActor
    func testCredentialsPreservedDuringPrewarming() {
        // Given: Simulate a scenario where keychain was previously configured
        UserDefaults.standard.set(true, forKey: isKeychainConfiguredKey)

        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )

        // When: Initialize during prewarming (protected data unavailable)
        _ = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfig,
            accessGroup: nil,
            migrateKeychainItemsOfUserSession: false,
            isProtectedDataAvailable: { false }
        )

        // Then: The flag should still be true (unchanged)
        let isConfigured = UserDefaults.standard.bool(forKey: isKeychainConfiguredKey)
        XCTAssertTrue(isConfigured, "isKeychainConfigured should remain unchanged during prewarming")
    }
}
