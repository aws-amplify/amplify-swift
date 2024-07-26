//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin

class CredentialStoreConfigurationTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        AuthSessionHelper.clearSession()
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
            credentials: awsCredentials)
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
        let newAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(userPoolConfiguration,
                                                                        configData)
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let updatedConfig = AuthConfiguration.userPoolsAndIdentityPools(
            UserPoolConfigurationData(poolId: Defaults.userPoolId,
                                      clientId: Defaults.appClientId,
                                      region: Defaults.regionString,
                                      clientSecret: Defaults.appClientSecret,
                                      pinpointAppId: "somethingNew"),
            Defaults.makeIdentityConfigData())
        // When configuration don't change changed
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: updatedConfig)

        // Then
        guard let credentials = try? newCredentialStore.retrieveCredential(),
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
    ///    - The keychain should be cleared
    ///
    func testCredentialsMigratedOnNotSupportedConfigurationChange() {
        // Given
        let identityId = "identityId"
        let awsCredentials = AuthAWSCognitoCredentials.testData
        let initialCognitoCredentials = AmplifyCredentials.identityPoolOnly(
            identityID: identityId,
            credentials: awsCredentials)
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
            Defaults.makeIdentityConfigData())
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: newAuthConfig)

        // Then
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNil(credentials)
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
            credentials: awsCredentials)

        let initialAuthConfig = AuthConfiguration.identityPools(Defaults.makeIdentityConfigData())
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration changed
        let newAuthConfig = AuthConfiguration.identityPools(IdentityPoolConfigurationData(poolId: "changed",
                                                                                          region: "changed"))
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
        let credentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)
        do {
            try credentialStore.saveCredential(initialCognitoCredentials)
        } catch {
            XCTFail("Unable to save credentials")
        }

        // When configuration don't change changed
        UserDefaults.standard.removeObject(forKey: "amplify_secure_storage_scopes.awsCognitoAuthPlugin.isKeychainConfigured")
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)

        // Then credentials should be nil
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNil(credentials)
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
            credentials: awsCredentials)
        let initialAuthConfig = AuthConfiguration.userPoolsAndIdentityPools(
            Defaults.makeDefaultUserPoolConfigData(),
            Defaults.makeIdentityConfigData())
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
              case .userPoolAndIdentityPool(let retrievedTokens,
                                            let retrievedIdentityID,
                                            let retrievedCredentials) = credentials else {
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
}
