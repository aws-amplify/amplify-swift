//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAmplifyKeychain

package struct AWSCognitoAuthCredentialStore {

    // Credential store constants. The services and the access-group members below are internal, not private,
    // because the access-group handling in `AWSCognitoAuthCredentialStore+AccessGroup.swift` reads them.
    let service = "com.amplify.awsCognitoAuthPlugin"
    let sharedService = "com.amplify.awsCognitoAuthPluginShared"
    private let sessionKey = "session"
    private let deviceMetadataKey = "deviceMetadata"
    private let deviceASFKey = "deviceASF"
    private let authConfigurationKey = "authConfiguration"

    // User defaults constants
    private let userDefaultsNameSpace = "amplify_secure_storage_scopes.awsCognitoAuthPlugin"
    /// This UserDefaults Key is use to retrieve the stored access group to determine
    /// which access group the migration should happen from
    /// If none is found, the unshared service is used for migration and all items
    /// under that service are queried
    var accessGroupKey: String {
        "\(userDefaultsNameSpace).accessGroup"
    }

    /// Creates the item store behind every keychain store this type uses, from a service and an optional
    /// access group.
    package typealias KeychainStoreFactory = @Sendable (_ service: String, _ accessGroup: String?) -> any KeychainItemStoreBehavior

    private let authConfiguration: AuthConfiguration
    private let keychain: EngineKeychainStore
    let userDefaults: UserDefaults
    let accessGroup: String?
    let makeKeychainStore: KeychainStoreFactory

    package init(
        authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrateKeychainItemsOfUserSession: Bool = false
    ) {
        self.init(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrateKeychainItemsOfUserSession,
            userDefaults: .standard,
            makeKeychainStore: { EngineKeychainStore.makeItemStore(service: $0, accessGroup: $1) }
        )
    }

    /// A test seam: `userDefaults` and `makeKeychainStore` are always `.standard` and
    /// `EngineKeychainStore.makeItemStore(service:accessGroup:)` outside tests. `makeKeychainStore` also
    /// reaches the access-group migration.
    package init(
        authConfiguration: AuthConfiguration,
        accessGroup: String?,
        migrateKeychainItemsOfUserSession: Bool,
        userDefaults: UserDefaults,
        makeKeychainStore: @escaping KeychainStoreFactory
    ) {
        self.authConfiguration = authConfiguration
        self.accessGroup = accessGroup
        self.userDefaults = userDefaults
        self.makeKeychainStore = makeKeychainStore
        if let accessGroup {
            self.keychain = Self.keychainStore(sharedService, accessGroup, makeKeychainStore)
        } else {
            self.keychain = Self.keychainStore(service, nil, makeKeychainStore)
        }

        let oldAccessGroup = retrieveStoredAccessGroup()
        if migrateKeychainItemsOfUserSession {
            try? migrateKeychainItemsToAccessGroup()
        } else if oldAccessGroup == nil && oldAccessGroup != accessGroup {
            // Only clear the old keychain if the shared keychain doesn't already have items.
            // This prevents data loss when an app extension (e.g., widget) initializes before
            // the main app has a chance to record the migration in UserDefaults, since
            // UserDefaults is not shared between app and extensions.
            //
            // Standalone clients keep their session records (`amplify.<digits>.…`) in this same service, so only
            // the plugin's own items are removed. If they cannot be listed, nothing is removed.
            if !sharedKeychainHasItems(accessGroup: accessGroup) {
                try? Self.keychainStore(service, nil, makeKeychainStore).removeAllExceptSessionRecords()
            }
        }

        saveStoredAccessGroup()

        // NOTE: We intentionally do NOT clear keychain credentials on app reinstall.
        // Previously, this code checked a UserDefaults flag (isKeychainConfiguredKey) to detect
        // fresh installs and clear orphaned keychain items. However, this approach was unreliable
        // because UserDefaults can return false during iOS prewarming (background app launch after
        // device reboot) when protected data is not yet available. This caused valid credentials
        // to be incorrectly cleared, resulting in random user logouts.
        //
        // Keychain items persisting across app reinstalls is iOS's default behavior. Any stale
        // credentials will naturally fail authentication and trigger a proper sign-out flow.
        // See: https://github.com/aws-amplify/amplify-swift/issues/3972

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
            // Clear the old credentials. Not a bare `_remove(oldNameSpace)`: that would leave the old
            // namespace's default-session record, if the Cognito client wrote one, as the only record
            // there, and returning to that configuration would then sign its user back in from it.
            try? removeSession(for: oldAuthConfigData)
        }
    }

    private func storeKey(for authConfiguration: AuthConfiguration) -> String {
        let prefix = "amplify"
        let suffix = poolNamespace(for: authConfiguration)

        return "\(prefix).\(suffix)"
    }

    /// The pool IDs every key for this configuration is scoped by.
    private func poolNamespace(for authConfiguration: AuthConfiguration) -> String {
        switch authConfiguration {
        case .userPools(let userPoolConfigurationData):
            return userPoolConfigurationData.poolId
        case .identityPools(let identityPoolConfigurationData):
            return identityPoolConfigurationData.poolId
        case .userPoolsAndIdentityPools(let userPoolConfigurationData, let identityPoolConfigurationData):
            return "\(userPoolConfigurationData.poolId).\(identityPoolConfigurationData.poolId)"
        }
    }

    private func generateSessionKey(for authConfiguration: AuthConfiguration) -> String {
        return "\(storeKey(for: authConfiguration)).\(sessionKey)"
    }

    // Internal rather than private so unit tests can pin the generated key.
    /// The account of the Cognito client's default-session record for this configuration,
    /// `amplify.1.<pool namespace>.$default.session`. Read only; see `DefaultSessionRecordReader`.
    package func generateDefaultSessionRecordKey(for authConfiguration: AuthConfiguration) -> String {
        DefaultSessionRecordReader.account(forPoolNamespace: poolNamespace(for: authConfiguration))
    }

    // The device metadata key lowercases the username and the ASF device key does not. Existing
    // device records are stored under both keys as they are, so neither may change.
    // Internal rather than private so unit tests can pin the generated keys.
    package func generateDeviceMetadataKey(for username: String) -> String {
            return "\(storeKey(for: authConfiguration)).\(username.lowercased()).\(deviceMetadataKey)"
    }

    // Internal rather than private so unit tests can pin the generated keys.
    package func generateASFDeviceKey(for username: String) -> String {
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

    /// A test seam: a store over `keychain`, with no access group. Runs the configuration-change
    /// handling the other initializer runs, and none of its access-group handling — so
    /// `userDefaults` and `makeKeychainStore`, which only that handling uses, are never read.
    package init(authConfiguration: AuthConfiguration, keychain: any KeychainItemStoreBehavior) {
        self.authConfiguration = authConfiguration
        self.accessGroup = nil
        self.keychain = EngineKeychainStore(keychain)
        self.userDefaults = .standard
        self.makeKeychainStore = { EngineKeychainStore.makeItemStore(service: $0, accessGroup: $1) }
        restoreCredentialsOnConfigurationChanges(currentAuthConfig: authConfiguration)
        saveAuthConfiguration(authConfig: authConfiguration)
    }

}

extension AWSCognitoAuthCredentialStore: AmplifyAuthCredentialStoreBehavior {

    package func saveCredential(_ credential: AmplifyCredentials) throws {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let encodedCredentials = try encode(object: credential)
        try keychain._set(encodedCredentials, key: authCredentialStoreKey)
    }

    /// Reads this plugin's session record and, only when there is no such item, the Cognito client's
    /// default-session record for the same configuration.
    ///
    /// This plugin's record always wins when it exists, even if it cannot be decoded. Any failure to read
    /// it other than "not found", such as a locked device, is thrown as it always was and never answered
    /// from the client's record. The client's record only ever contributes a signed-in session: when it
    /// is absent, signed out or unreadable, this throws `itemNotFound`, exactly as before it existed.
    package func retrieveCredential() throws -> AmplifyCredentials {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let authCredentialData: Data
        do {
            authCredentialData = try keychain._getData(authCredentialStoreKey)
        } catch EngineCredentialStoreError.itemNotFound {
            return try retrieveDefaultSessionRecord()
        }
        let amplifyCredential: AmplifyCredentials = try decode(data: authCredentialData)
        return amplifyCredential
    }

    package func deleteCredential() throws {
        try removeSession(for: authConfiguration)
    }

    package func saveDevice(_ deviceMetadata: DeviceMetadata, for username: String) throws {
        let key = generateDeviceMetadataKey(for: username)
        let encodedMetadata = try encode(object: deviceMetadata)
        try keychain._set(encodedMetadata, key: key)
    }

    package func retrieveDevice(for username: String) throws -> DeviceMetadata {
        let key = generateDeviceMetadataKey(for: username)
        let encodedDeviceMetadata = try keychain._getData(key)
        let deviceMetadata: DeviceMetadata = try decode(data: encodedDeviceMetadata)
        return deviceMetadata
    }

    package func removeDevice(for username: String) throws {
        let key = generateDeviceMetadataKey(for: username)
        try keychain._remove(key)
    }

    package func saveASFDevice(_ deviceId: String, for username: String) throws {
        let key = generateASFDeviceKey(for: username)
        let encodedMetadata = try encode(object: deviceId)
        try keychain._set(encodedMetadata, key: key)
    }

    package func retrieveASFDevice(for username: String) throws -> String {
        let key = generateASFDeviceKey(for: username)
        let encodedData = try keychain._getData(key)
        let asfID: String = try decode(data: encodedData)
        return asfID
    }

    package func removeASFDevice(for username: String) throws {
        let key = generateASFDeviceKey(for: username)
        try keychain._remove(key)
    }

    /// The fallback read of `retrieveCredential()`, taken only when this plugin has no record.
    private func retrieveDefaultSessionRecord() throws -> AmplifyCredentials {
        let key = generateDefaultSessionRecordKey(for: authConfiguration)
        switch try DefaultSessionRecordReader.read(key, from: keychain) {
        case .signedIn(let credentials):
            log.verbose("[AWSCognitoAuthCredentialStore] Read the session from the Cognito client's default session record")
            return credentials
        case .unreadable(let reason):
            log.warn("[AWSCognitoAuthCredentialStore] Ignoring the Cognito client's default session record: \(reason)")
            throw EngineCredentialStoreError.itemNotFound
        case .signedOut, nil:
            throw EngineCredentialStoreError.itemNotFound
        }
    }

    /// Ends this plugin's session for a configuration so that no later read brings it back.
    ///
    /// While the Cognito client has a default-session record in the same namespace, deleting this
    /// plugin's record would expose the client's to `retrieveCredential()`'s fallback, and the user just
    /// signed out would be signed in again from it on the next launch. This plugin may not delete or
    /// rewrite that record, so it writes `.noCredentials` over its own record instead: this plugin's own
    /// stored format, read by every release as signed out, and present, so it takes precedence over the
    /// client's record. Without a client record, the record is deleted exactly as it always was.
    ///
    /// If that write fails, the record is deleted anyway before the error is thrown: a live record left
    /// in place would sign the user back in by itself, so deleting it is never worse. Without a client
    /// record that is exactly the old behaviour.
    private func removeSession(for authConfiguration: AuthConfiguration) throws {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        guard defaultSessionRecordMayExist(for: authConfiguration) else {
            try keychain._remove(authCredentialStoreKey)
            return
        }
        do {
            let signedOut = try encode(object: AmplifyCredentials.noCredentials)
            try keychain._set(signedOut, key: authCredentialStoreKey)
        } catch {
            try? keychain._remove(authCredentialStoreKey)
            throw error
        }
    }

    /// Whether the Cognito client may have a default-session record for a configuration. `true` when
    /// that cannot be determined: the `.noCredentials` record it leads to is harmless if unneeded.
    private func defaultSessionRecordMayExist(for authConfiguration: AuthConfiguration) -> Bool {
        do {
            _ = try keychain._getData(generateDefaultSessionRecordKey(for: authConfiguration))
            return true
        } catch EngineCredentialStoreError.itemNotFound {
            return false
        } catch {
            return true
        }
    }

}

package extension AWSCognitoAuthCredentialStore {
    /// A keychain store over the item store `makeKeychainStore` builds for `service` and `accessGroup`.
    static func keychainStore(
        _ service: String,
        _ accessGroup: String?,
        _ makeKeychainStore: KeychainStoreFactory
    ) -> EngineKeychainStore {
        EngineKeychainStore(makeKeychainStore(service, accessGroup))
    }
}

/// Helpers for encode and decoding
private extension AWSCognitoAuthCredentialStore {

    func encode(object: some Codable) throws -> Data {
        do {
            return try JSONEncoder().encode(object)
        } catch {
            throw EngineCredentialStoreError.codingError("Error occurred while encoding credentials", error)
        }
    }

    func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw EngineCredentialStoreError.codingError("Error occurred while decoding credentials", error)
        }
    }

}

package extension AWSCognitoAuthCredentialStore {
    /// No environment is in scope, so these lines go through the global router.
    static let log = EngineLog.logger(.category("AWSCognitoAuthCredentialStore"))

    /// `KeychainStoreMigrator.log`, its `DefaultLogger` default: the category `KeychainStoreMigrator`.
    static let migratorLog = EngineLog.logger(.category("KeychainStoreMigrator"))

    var log: EngineLogger {
        Self.log
    }
}
