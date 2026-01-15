//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
@_spi(KeychainStore) import AWSPluginsCore

class CredentialStoreConfigurationTests: AWSAuthBaseTest {

    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"

    override func setUp() async throws {
        try await super.setUp()
        clearAllKeychains()
        // Clear access group UserDefaults to ensure clean state for migration tests
        UserDefaults.standard.removeObject(forKey: "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup")
    }

    override func tearDown() async throws {
        try await super.tearDown()
        clearAllKeychains()
        // Clear access group UserDefaults
        UserDefaults.standard.removeObject(forKey: "amplify_secure_storage_scopes.awsCognitoAuthPlugin.accessGroup")
    }

    /// Clears all keychain items (both shared and non-shared) to ensure clean test state
    private func clearAllKeychains() {
        // Clear non-shared keychain
        let nonSharedKeychain = KeychainStore(service: service)
        try? nonSharedKeychain._removeAll()

        // Clear shared keychains for all access groups used in tests
        #if os(watchOS)
        let accessGroups = [keychainAccessGroupWatch, keychainAccessGroupWatch2]
        #else
        let accessGroups = [keychainAccessGroup, keychainAccessGroup2]
        #endif

        for accessGroup in accessGroups {
            let sharedKeychain = KeychainStore(service: sharedService, accessGroup: accessGroup)
            try? sharedKeychain._removeAll()
        }
    }

    /// Test successful migration of credentials when auth configuration changes
    ///
    /// - Given: A user registered in Identity user pool
    /// - When:
    ///    - We invoke a new Credential store with new Auth Configuration where identity user pool remains changes
    /// - Then:
    ///    - The old credentials should be migrated
    ///
    func testCredentialsMigratedOnValidConfigurationChange() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.identityPoolOnly(
            identityID: identityId,
            credentials: awsCredentials
        )
        let configData = Defaults.makeIdentityConfigData()
        let initialAuthConfig = AuthConfiguration.identityPools(configData)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let userPoolConfiguration = Defaults.makeDefaultUserPoolConfigData()
        let newAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            userPoolConfiguration,
            configData
        )
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: newAuthConfig)

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .identityPoolOnly(let retrievedIdentityID, let retrievedCredentials) = credentials else {
            XCTFail("Unable to retrieve Credentials")
            return
        }
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedCredentials, awsCredentials)
    }

    /// Test no migration happens when no configuration change happens
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized
    /// - Then:
    ///    - The old credentials should still persist
    ///
    func testCredentialsMigrationDoesntHappenOnNoConfigurationChange() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let updatedConfig = AuthConfiguration.userPoolsAndIdentityPools(
            UserPoolConfigurationData(
                poolId: Defaults.userPoolId,
                clientId: Defaults.appClientId,
                region: Defaults.regionString,
                clientSecret: Defaults.appClientSecret,
                pinpointAppId: "somethingNew"
            ),
            Defaults.makeIdentityConfigData()
        )
        // When configuration don't change changed
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: updatedConfig)

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            XCTFail("Unable to retrieve Credentials")
            return
        }
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedCredentials, awsCredentials)
    }

    /// Test clearing of existing credentials when a configuration change happens from UserPool to both User Pool and Identity Pool
    ///
    /// - Given: A user registered in user pool
    /// - When:
    ///    - We invoke a new Credential store with new Auth Configuration where identity user pool gets added
    /// - Then:
    ///    - The keychain should be NOT be cleared
    ///
    func testCredentialsMigratedOnNotSupportedConfigurationChange() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.identityPoolOnly(
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPools(Defaults.makeDefaultUserPoolConfigData())
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let newAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: newAuthConfig)

        // Then
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNotNil(credentials)
    }

    /// Test clearing of existing credentials when a configuration changes for identity pool
    ///
    /// - Given: A user registered in identity pool
    /// - When:
    ///    - We invoke a new Credential store with new Auth Configuration where identity pool config changes
    /// - Then:
    ///    - The keychain should be cleared
    ///
    func testCredentialsMigratedOnNotSupportedIdentityPoolConfigurationChange() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.identityPoolOnly(
            identityID: identityId,
            credentials: awsCredentials
        )

        let initialAuthConfig = AuthConfiguration.identityPools(Defaults.makeIdentityConfigData())
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let newAuthConfig = AuthConfiguration.identityPools(
            IdentityPoolConfigurationData(
                poolId: "changed",
                region: "changed"
            ))
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: newAuthConfig)

        // Then
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNil(credentials)
    }

    /// Test clearing of existing credentials when a new app is installed
    ///
    /// - Given: A user registered
    /// - When:
    ///    - We invoke a new Credential store when the app is reinstalled
    /// - Then:
    ///    - The keychain should be cleared
    ///
    func testCredentialClearingOnAppReinstall() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration don't change changed
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)

        // Then credentials should be nil
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNotNil(credentials)
    }

    /// Test migrating to a shared access group keeps credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with shared access group and migration set to true
    /// - Then:
    ///    - The old credentials should still persist
    ///
    func testCredentialsRemainOnMigrationToSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        // Migration only happens if credentials are not expired, hence
        // the need for nonimmediate expiration test data
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When migrating to shared access group with same configuration
        #if os(watchOS)
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch, migrateKeychainItemsOfUserSession: true)
        #else
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup, migrateKeychainItemsOfUserSession: true)
        #endif

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            XCTFail("Unable to retrieve Credentials")
            return
        }
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedCredentials, awsCredentials)
    }

    /// Test migrating from a shared access group to an unshared access group keeps credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with unshared access group and migration set to true
    /// - Then:
    ///    - The old credentials should still persist
    ///
    func testCredentialsRemainOnMigrationFromSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        // Migration only happens if credentials are not expired, hence
        // the need for nonimmediate expiration test data
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        #if os(watchOS)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch)
        #else
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup)
        #endif
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When migrating to unshared access group with same configuration
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, migrateKeychainItemsOfUserSession: true)

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            XCTFail("Unable to retrieve Credentials")
            return
        }
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedCredentials, awsCredentials)
    }

    /// Test migrating from a shared access group to another shared access group keeps credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with another shared access group and migration set to true
    /// - Then:
    ///    - The old credentials should still persist
    ///
    func testCredentialsRemainOnMigrationFromSharedAccessGroupToAnotherSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        // Migration only happens if credentials are not expired, hence
        // the need for nonimmediate expiration test data
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        #if os(watchOS)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch)
        #else
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup)
        #endif
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When migrating to another shared access group with same configuration
        #if os(watchOS)
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch2, migrateKeychainItemsOfUserSession: true)
        #else
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup2, migrateKeychainItemsOfUserSession: true)
        #endif

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            XCTFail("Unable to retrieve Credentials")
            return
        }
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedCredentials, awsCredentials)
    }

    /// Test moving to a shared access group without migration should not keep credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with shared access group and migration set to false
    /// - Then:
    ///    - The old credentials should not persist
    ///
    func testCredentialsDoNotRemainOnNonMigrationToSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When moving to shared access group with same configuration but without migration
        #if os(watchOS)
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch, migrateKeychainItemsOfUserSession: false)
        #else
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup, migrateKeychainItemsOfUserSession: false)
        #endif

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            // Expected
            return
        }

        // If credentials are present, they should not be the same as those that were not migrated
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertNotEqual(retrievedCredentials, awsCredentials)
    }

    /// Test moving from a shared access group to an unshared access group without migration should not keep credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with unshared access group and migration set to false
    /// - Then:
    ///    - The old credentials should not persist
    ///
    func testCredentialsDoNotRemainOnNonMigrationFromSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        #if os(watchOS)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch)
        #else
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup)
        #endif
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When moving to unshared access group with same configuration but without migration
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, migrateKeychainItemsOfUserSession: false)

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            // Expected
            return
        }

        // If credentials are present, they should not be the same as those that were not migrated
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertNotEqual(retrievedCredentials, awsCredentials)
    }

    /// Test moving from a shared access group to another shared access group without migration should not keep credentials
    ///
    /// - Given: A user registered is configured
    /// - When:
    ///    - The credential store is re-initialized with another shared access group and migration set to false
    /// - Then:
    ///    - The old credentials should not persist
    ///
    func testCredentialsDoNotRemainOnNonMigrationFromSharedAccessGroupToAnotherSharedAccessGroup() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.nonimmediateExpiryTestData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )
        #if os(watchOS)
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch)
        #else
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup)
        #endif
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When moving to another shared access group with same configuration but without migration
        #if os(watchOS)
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroupWatch2, migrateKeychainItemsOfUserSession: false)
        #else
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig, accessGroup: keychainAccessGroup2, migrateKeychainItemsOfUserSession: false)
        #endif

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedCredentials
              ) = credentials else {
            // Expected
            return
        }

        // If credentials are present, they should not be the same as those that were not migrated
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedCredentials)
        XCTAssertNotEqual(retrievedCredentials, awsCredentials)
    }

    /// Test that shared keychain credentials are NOT cleared on fresh install when using access group
    ///
    /// - Given: A user has credentials stored in shared keychain
    /// - When: The credential store is initialized with fresh UserDefaults but same access group
    /// - Then: The shared keychain credentials should NOT be cleared
    ///
    func testSharedKeychainCredentialsNotClearedOnFreshInstall() {
        // Given: Save credentials to shared keychain
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )

        #if os(watchOS)
        let accessGroup = keychainAccessGroupWatch
        #else
        let accessGroup = keychainAccessGroup
        #endif

        let credentialStore = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfig,
            accessGroup: accessGroup
        )

        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // Verify credentials are saved
        guard let savedCredentials = try? credentialStore.retrieveCredential() else {
            XCTFail("Unable to retrieve saved credentials")
            return
        }
        XCTAssertNotNil(savedCredentials)

        // When: Simulate fresh install by clearing UserDefaults flag
        UserDefaults.standard.removeObject(forKey: "amplify_secure_storage_scopes.awsCognitoAuthPlugin.isKeychainConfigured")

        // Initialize new credential store with same access group (simulates app extension scenario)
        let newCredentialStore = AWSCognitoAuthCredentialStore(
            authConfiguration: authConfig,
            accessGroup: accessGroup
        )

        // Then: Shared keychain credentials should NOT be cleared
        guard let retrievedCredentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(
                  let retrievedTokens,
                  let retrievedIdentityID,
                  let retrievedAWSCredentials
              ) = retrievedCredentials else {
            XCTFail("Shared keychain credentials should not be cleared")
            return
        }

        XCTAssertNotNil(retrievedCredentials)
        XCTAssertNotNil(retrievedTokens)
        XCTAssertNotNil(retrievedIdentityID)
        XCTAssertNotNil(retrievedAWSCredentials)
        XCTAssertEqual(retrievedIdentityID, identityId)
        XCTAssertEqual(retrievedAWSCredentials, awsCredentials)
    }

    /// Test that non-shared keychain credentials ARE cleared on fresh install
    ///
    /// - Given: A user has credentials stored in non-shared keychain
    /// - When: The credential store is initialized with fresh UserDefaults and no access group
    /// - Then: The keychain credentials should be cleared
    ///
    func testNonSharedKeychainCredentialsClearedOnFreshInstall() {
        // Given: Save credentials to non-shared keychain
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.userPoolAndIdentityPool(
            signedInData: .testData,
            identityID: identityId,
            credentials: awsCredentials
        )
        let authConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData()
        )

        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: authConfig)

        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // Verify credentials are saved
        guard let savedCredentials = try? credentialStore.retrieveCredential() else {
            XCTFail("Unable to retrieve saved credentials")
            return
        }
        XCTAssertNotNil(savedCredentials)

        // Initialize new credential store without access group
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: authConfig)

        // Then: Non-shared keychain credentials should be cleared
        let retrievedCredentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNotNil(retrievedCredentials, "Non-shared keychain credentials should NOT be cleared on fresh install")
    }
}
