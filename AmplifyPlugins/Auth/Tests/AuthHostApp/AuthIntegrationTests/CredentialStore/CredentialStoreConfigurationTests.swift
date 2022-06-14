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
        super.tearDown()
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
        let initialCognitoCredentials = AmplifyCredentials(
            userPoolTokens: nil,
            identityId: identityId,
            awsCredential: awsCredentials)
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
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(credentials?.identityId)
        XCTAssertNotNil(credentials?.awsCredential)
        XCTAssertEqual(credentials?.identityId, identityId)
        XCTAssertEqual(credentials?.awsCredential, awsCredentials)
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
        let initialCognitoCredentials = AmplifyCredentials(
            userPoolTokens: AWSCognitoUserPoolTokens.testData,
            identityId: identityId,
            awsCredential: awsCredentials)
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
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)

        // Then
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNotNil(credentials)
        XCTAssertNotNil(credentials?.identityId)
        XCTAssertNotNil(credentials?.awsCredential)
        XCTAssertEqual(credentials?.identityId, identityId)
        XCTAssertEqual(credentials?.awsCredential, awsCredentials)
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
        let initialCognitoCredentials = AmplifyCredentials(
            userPoolTokens: nil,
            identityId: identityId,
            awsCredential: awsCredentials)
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
        let initialCognitoCredentials = AmplifyCredentials(
            userPoolTokens: nil,
            identityId: identityId,
            awsCredential: awsCredentials)
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
        let initialCognitoCredentials = AmplifyCredentials(
            userPoolTokens: AWSCognitoUserPoolTokens.testData,
            identityId: identityId,
            awsCredential: awsCredentials)
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
        UserDefaults.standard.removeObject(forKey: "isKeychainConfigured")
        let newCredentialStore = AWSCognitoAuthCredentialStore(authConfiguration: initialAuthConfig)

        // Then credentials should be nil
        let credentials = try? newCredentialStore.retrieveCredential()
        XCTAssertNil(credentials)
    }
}
