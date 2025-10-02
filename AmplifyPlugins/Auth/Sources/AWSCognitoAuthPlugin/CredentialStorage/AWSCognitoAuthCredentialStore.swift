//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@_spi(KeychainStore) import AWSPluginsCore

struct AWSCognitoAuthCredentialStore {

    // Credential store constants
    private let service = "com.amplify.awsCognitoAuthPlugin"
    private let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let sessionKey = "session"
    private let deviceMetadataKey = "deviceMetadata"
    private let deviceASFKey = "deviceASF"
    private let authConfigurationKey = "authConfiguration"

    // User defaults constants
    private let userDefaultsNameSpace = "amplify_secure_storage_scopes.awsCognitoAuthPlugin"
    /// This UserDefault Key is used to check if Keychain already has items stored on a fresh install
    /// If this flag doesn't exist, previous keychain values for Amplify would be wiped out
    private var isKeychainConfiguredKey: String {
        "\(userDefaultsNameSpace).isKeychainConfigured"
    }
    /// This UserDefaults Key is use to retrieve the stored access group to determine
    /// which access group the migration should happen from
    /// If none is found, the unshared service is used for migration and all items
    /// under that service are queried
    private var accessGroupKey: String {
        "\(userDefaultsNameSpace).accessGroup"
    }

    private let authConfiguration: AuthConfiguration
    private let keychain: KeychainStoreBehavior
    private let userDefaults = UserDefaults.standard
    private let accessGroup: String?

    init(
        authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrateKeychainItemsOfUserSession: Bool = false
    ) {
        self.authConfiguration = authConfiguration
        self.accessGroup = accessGroup
        if let accessGroup {
            self.keychain = KeychainStore(service: sharedService, accessGroup: accessGroup)
        } else {
            self.keychain = KeychainStore(service: service)
        }

        let oldAccessGroup = retrieveStoredAccessGroup()
        if migrateKeychainItemsOfUserSession {
            try? migrateKeychainItemsToAccessGroup()
        } else if oldAccessGroup == nil && oldAccessGroup != accessGroup {
            try? KeychainStore(service: service)._removeAll()
        }

        saveStoredAccessGroup()

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
        let newUserPoolConfiguration = currentAuthConfig.getUserPoolConfiguration()

        /// Migrate if
        ///  - Old User Pool Config didn't exist
        ///  - New Identity Config Data exists
        ///  - Old Identity Pool Config == New Identity Pool Config
        if oldUserPoolConfiguration == nil &&
            newIdentityConfigData != nil &&
            oldIdentityPoolConfiguration == newIdentityConfigData {
            // retrieve data from the old namespace and save with the new namespace
            if let oldCognitoCredentialsData = try? keychain._getData(oldNameSpace) {
                try? keychain._set(oldCognitoCredentialsData, key: newNameSpace)
            }
        /// Migrate if
        ///  - Old config and new config are different
        ///  - Old Userpool Existed
        ///  - Old and new user pool namespacing is the same
        } else if oldAuthConfigData != currentAuthConfig &&
                    oldUserPoolConfiguration != nil &&
                    UserPoolConfigurationData.isNamespacingEqual(
                        lhs: oldUserPoolConfiguration,
                        rhs: newUserPoolConfiguration
                    ) {
            // retrieve data from the old namespace and save with the new namespace
            if let oldCognitoCredentialsData = try? keychain._getData(oldNameSpace) {
                try? keychain._set(oldCognitoCredentialsData, key: newNameSpace)
            }
        } else if oldAuthConfigData != currentAuthConfig &&
                    oldNameSpace != newNameSpace {
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
        with configuration: AuthConfiguration
    ) -> String {
            return "\(storeKey(for: authConfiguration)).\(username).\(deviceMetadataKey)"
    }

    private func generateASFDeviceKey(
        for username: String,
        with configuration: AuthConfiguration
    ) -> String {
            return "\(storeKey(for: authConfiguration)).\(username).\(deviceASFKey)"
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

    func saveCredential(_ credential: AmplifyCredentials) throws {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let encodedCredentials = try encode(object: credential)
        try keychain._set(encodedCredentials, key: authCredentialStoreKey)
    }

    func retrieveCredential() throws -> AmplifyCredentials {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let authCredentialData = try keychain._getData(authCredentialStoreKey)
        let amplifyCredential: AmplifyCredentials = try decode(data: authCredentialData)
        return amplifyCredential
    }

    func deleteCredential() throws {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        try keychain._remove(authCredentialStoreKey)
    }

    func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        let encodedMetadata = try encode(object: deviceMetadata)
        try keychain._set(encodedMetadata, key: key)
    }

    func retrieveDevice(for username: String) throws -> DeviceMetadata {
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        let encodedDeviceMetadata = try keychain._getData(key)
        let deviceMetadata: DeviceMetadata = try decode(data: encodedDeviceMetadata)
        return deviceMetadata
    }

    func removeDevice(for username: String) throws {
        let key = generateDeviceMetadataKey(for: username, with: authConfiguration)
        try keychain._remove(key)
    }

    func saveASFDevice(_ deviceId: String, for username: String) throws {
        let key = generateASFDeviceKey(for: username, with: authConfiguration)
        let encodedMetadata = try encode(object: deviceId)
        try keychain._set(encodedMetadata, key: key)
    }

    func retrieveASFDevice(for username: String) throws -> String {
        let key = generateASFDeviceKey(for: username, with: authConfiguration)
        let encodedData = try keychain._getData(key)
        let asfID: String = try decode(data: encodedData)
        return asfID
    }

    func removeASFDevice(for username: String) throws {
        let key = generateASFDeviceKey(for: username, with: authConfiguration)
        try keychain._remove(key)
    }

    private func clearAllCredentials() throws {
        try keychain._removeAll()
    }

    private func retrieveStoredAccessGroup() -> String? {
        return userDefaults.string(forKey: accessGroupKey)
    }

    private func saveStoredAccessGroup() {
        if let accessGroup {
            userDefaults.set(accessGroup, forKey: accessGroupKey)
        } else {
            userDefaults.removeObject(forKey: accessGroupKey)
        }
    }

    private func migrateKeychainItemsToAccessGroup() throws {
        let oldAccessGroup = retrieveStoredAccessGroup()

        if oldAccessGroup == accessGroup {
            log.info("[AWSCognitoAuthCredentialStore] Stored access group is the same as current access group, aborting migration")
            return
        }

        let oldService = oldAccessGroup != nil ? sharedService : service
        let newService = accessGroup != nil ? sharedService : service

        do {
            try KeychainStoreMigrator(oldService: oldService, newService: newService, oldAccessGroup: oldAccessGroup, newAccessGroup: accessGroup).migrate()
        } catch {
            log.error("[AWSCognitoAuthCredentialStore] Migration has failed")
            return
        }

        log.verbose("[AWSCognitoAuthCredentialStore] Migration of keychain items from old access group to new access group successful")
    }

}

/// Helpers for encode and decoding
private extension AWSCognitoAuthCredentialStore {

    func encode(object: some Codable) throws -> Data {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            throw KeychainStoreError.codingError("Error occurred while encoding credentials", error)
        }
    }

    func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw KeychainStoreError.codingError("Error occurred while decoding credentials", error)
        }
    }

}

extension AWSCognitoAuthCredentialStore: DefaultLogger { }
