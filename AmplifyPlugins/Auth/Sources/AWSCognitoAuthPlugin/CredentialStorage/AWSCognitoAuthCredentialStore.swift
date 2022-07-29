//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
@_spi(KeychainStore) import AWSPluginsCore

struct AWSCognitoAuthCredentialStore {

    // Credential store constants
    private let service = "com.amplify.credentialStore"
    private let sessionKey = "session"
    private let deviceMetadataKey = "deviceMetadata"
    private let authConfigurationKey = "authConfiguration"

    // User defaults constants
    /// This UserDefault Key is used to check if Keychain already has items stored on a fresh install
    /// If this flag doesn't exist, previous keychain values for Amplify would be wiped out
    private let isKeychainConfiguredKey = "isKeychainConfigured"

    private let authConfiguration: AuthConfiguration
    private let keychain: KeychainStoreBehavior
    private let userDefaults = UserDefaults.standard

    init(authConfiguration: AuthConfiguration, accessGroup: String? = nil) {
        self.authConfiguration = authConfiguration
        self.keychain = KeychainStore(service: service, accessGroup: accessGroup)

        if !userDefaults.bool(forKey: isKeychainConfiguredKey) {
            try? clearAllCredentials()
            userDefaults.set(true, forKey: isKeychainConfiguredKey)
        }

        restoreCredentialsOnConfigurationChanges(currentAuthConfig: authConfiguration)
        // Save the current configuration
        saveAuthConfiguration(authConfig: authConfiguration)
    }

    // The method is responsible for migrating any old credentials to the new namespace
    private func restoreCredentialsOnConfigurationChanges(currentAuthConfig: AuthConfiguration) {

        guard let oldAuthConfigData = getAuthConfiguration() else {
            return
        }
        let oldNameSpace = generateSessionKey(for: oldAuthConfigData)
        let newNameSpace = generateSessionKey(for: currentAuthConfig)

        let oldUserPoolConfiguration = oldAuthConfigData.getUserPoolConfiguration()
        let oldIdentityPoolConfiguration = oldAuthConfigData.getIdentityPoolConfiguration()
        let newIdentityConfigData = currentAuthConfig.getIdentityPoolConfiguration()

        /// Only migrate if
        ///  - Old User Pool Config didn't exist
        ///  - New Identity Config Data exists
        ///  - Old Identity Pool Config == New Identity Pool Config
        if oldUserPoolConfiguration == nil &&
            newIdentityConfigData != nil &&
            oldIdentityPoolConfiguration == newIdentityConfigData
        {

            // retrieve data from the old namespace and save with the new namespace
            if let oldCognitoCredentialsData = try? keychain._getData(oldNameSpace) {
                try? keychain._set(oldCognitoCredentialsData, key: newNameSpace)
            }
        } else if oldAuthConfigData != currentAuthConfig {
            // Clear the old credentials
            try? keychain._remove(oldNameSpace)
        }
    }

    private func storeKey(for authConfiguration: AuthConfiguration) -> String {
        let prefix = "amplify"
        var suffix = ""

        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            suffix = userPoolConfigurationData.poolId
        case .identityPools(let identityPoolConfigurationData):
            suffix = identityPoolConfigurationData.poolId
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            suffix = "\(userPoolConfigurationData.poolId).\(identityPoolConfigurationData.poolId)"
        }

        return "\(prefix).\(suffix)"
    }

    private func generateSessionKey(for authConfiguration: AuthConfiguration) -> String {
        return "\(storeKey(for: authConfiguration)).\(sessionKey)"
    }

    private func generateDeviceMetadataKey(
        for username: String,
        with configuration: AuthConfiguration) -> String {
            return "\(storeKey(for: authConfiguration)).\(username).\(deviceMetadataKey)"
    }

    private func saveAuthConfiguration(authConfig: AuthConfiguration) {
        if let encodedAuthConfigData = try? encode(object: authConfig) {
            try? keychain._set(encodedAuthConfigData, key: authConfigurationKey)
        }
    }

    private func getAuthConfiguration() -> AuthConfiguration? {
        if let userPoolConfigData = try? keychain._getData(authConfigurationKey) {
            return try? decode(data: userPoolConfigData)
        }
        return nil
    }

}

extension AWSCognitoAuthCredentialStore: AmplifyAuthCredentialStoreBehavior {

    func saveCredential(_ credential: Codable) throws {
        guard let amplifyCredentials = credential as? AmplifyCredentials else {
            throw KeychainStoreError.codingError("Error occurred while saving credentials", nil)
        }
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let encodedCredentials = try encode(object: amplifyCredentials)
        try keychain._set(encodedCredentials, key: authCredentialStoreKey)
    }

    func retrieveCredential() throws -> Codable {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let authCredentialData = try keychain._getData(authCredentialStoreKey)
        let awsCredential: AmplifyCredentials = try decode(data: authCredentialData)
        return awsCredential
    }

    func deleteCredential() throws {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        try keychain._remove(authCredentialStoreKey)
    }

    func saveDevice(_ deviceMetadata: Codable, for username: String) throws {
        guard let deviceMetadata = deviceMetadata as? DeviceMetadata else {
            throw CredentialStoreError.codingError("Error occurred while device metadata", nil)
        }
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        let encodedMetadata = try encode(object: deviceMetadata)
        try keychain.set(encodedMetadata, key: key)
    }

    func retrieveDevice(for username: String) throws -> Codable {
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        let encodedDeviceMetadata = try keychain.getData(key)
        let deviceMetadata: DeviceMetadata = try decode(data: encodedDeviceMetadata)
        return deviceMetadata
    }

    func removeDevice(for username: String) throws {
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        try keychain.remove(key)
    }

    private func clearAllCredentials() throws {
        try keychain._removeAll()
    }

}

/// Helpers for encode and decoding
private extension AWSCognitoAuthCredentialStore {

    func encode<T: Codable>(object: T) throws -> Data {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            throw KeychainStoreError.codingError("Error occurred while encoding AWSCredentials", error)
        }
    }

    func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KeychainStoreError.codingError("Error occurred while decoding AWSCredentials", error)
        }
    }

}
