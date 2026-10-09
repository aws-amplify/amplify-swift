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
    /// The last segment of a session account (`sessionAccount(for:)`, `+ConfigurationChange.swift`).
    static let sessionKey = "session"
    private let deviceMetadataKey = "deviceMetadata"
    private let deviceASFKey = "deviceASF"
    private var authConfigurationKey: String { Self.authConfigurationAccount }

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
    /// The caller's logger: every line of this store, and of its keychain stores, goes through it.
    let logger: any EngineScopedLogger

    /// - Parameter logger: the caller's. The plugin passes its own, so its lines keep their categories.
    package init(
        authConfiguration: AuthConfiguration,
        accessGroup: String? = nil,
        migrateKeychainItemsOfUserSession: Bool = false,
        logger: any EngineScopedLogger
    ) {
        self.init(
            authConfiguration: authConfiguration,
            accessGroup: accessGroup,
            migrateKeychainItemsOfUserSession: migrateKeychainItemsOfUserSession,
            userDefaults: .standard,
            makeKeychainStore: { EngineKeychainStore.makeItemStore(service: $0, accessGroup: $1, logger: logger) },
            logger: logger
        )
    }

    /// A test seam: `userDefaults` and `makeKeychainStore` are always `.standard` and
    /// `EngineKeychainStore.makeItemStore(service:accessGroup:logger:)` outside tests. `makeKeychainStore` also
    /// reaches the access-group migration.
    package init(
        authConfiguration: AuthConfiguration,
        accessGroup: String?,
        migrateKeychainItemsOfUserSession: Bool,
        userDefaults: UserDefaults,
        makeKeychainStore: @escaping KeychainStoreFactory,
        logger: any EngineScopedLogger
    ) {
        self.authConfiguration = authConfiguration
        self.accessGroup = accessGroup
        self.userDefaults = userDefaults
        self.makeKeychainStore = makeKeychainStore
        self.logger = logger
        if let accessGroup {
            self.keychain = Self.keychainStore(sharedService, accessGroup, makeKeychainStore, logger: logger)
        } else {
            self.keychain = Self.keychainStore(service, nil, makeKeychainStore, logger: logger)
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
            // the plugin's own items are removed, with the Cognito client's default-session sidecar and
            // challenge items, which belong to the plugin's session. If they cannot be listed, nothing is removed.
            if !sharedKeychainHasItems(accessGroup: accessGroup) {
                try? Self.keychainStore(service, nil, makeKeychainStore, logger: logger)
                    .removeAllExceptSessionRecords(sparingDefaultSessionItems: false)
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

    // The method is responsible for migrating any old credentials to the new namespace. The decision is
    // `configurationChange(from:to:)` (`AWSCognitoAuthCredentialStore+ConfigurationChange.swift`), which the Cognito
    // client's default session also runs; this runs the same `_getData`, `_set` and `_remove` calls, in the same
    // order, with the same `try?`, as before it was extracted, and on a clear then removes the Cognito client's two
    // default-session items of the old namespace (below).
    private func restoreCredentialsOnConfigurationChanges(currentAuthConfig: AuthConfiguration) {
        switch Self.configurationChange(from: getAuthConfiguration(), to: currentAuthConfig) {
        case .unchanged:
            return
        case .carry(let fromAccount, let toAccount):
            // retrieve data from the old namespace and save with the new namespace
            if let oldCognitoCredentialsData = try? keychain._getData(fromAccount) {
                try? keychain._set(oldCognitoCredentialsData, key: toAccount)
            }
        case .clear(_, let previous):
            // Clear the old credentials. If that fails, the old login stays, and so do the client's items below.
            guard (try? removeSession(for: previous)) != nil else {
                return
            }
            // This store also removes two items it does not write itself. The Cognito client's default session
            // shares this store's saved login, and keeps two items beside it that describe that login: its label
            // and last user (`amplify.1.<pools>.$default.meta`), and its unfinished sign-in
            // (`amplify.1.<pools>.$default.challenge`). Once the old configuration's login is deleted here, they
            // describe a login that no longer exists, and the client would list a signed-out session (the label and
            // the last username) under the old configuration for a login nobody signed out of. The client removes
            // the same two items when it applies the same change itself. A carry keeps the old login, so it keeps
            // them too. Best effort: a missing item is not an error, and the keychain store logs a failure without
            // the item's key.
            let previousPools = Self.poolNamespace(of: previous)
            for account in SessionRecordAccount.defaultSessionItemAccounts(poolNamespace: previousPools) {
                try? keychain._remove(account)
            }
        }
    }

    /// `amplify.<pools>`: the prefix of every account of a configuration (`+ConfigurationChange.swift`).
    static func storeKey(for authConfiguration: AuthConfiguration) -> String {
        let prefix = "amplify"
        return "\(prefix).\(poolNamespace(of: authConfiguration))"
    }

    /// `<pools>` of `storeKey(for:)`: the user pool ID, the identity pool ID, or both joined by `.`. The Cognito
    /// client names a configuration's records by the same string.
    static func poolNamespace(of authConfiguration: AuthConfiguration) -> String {
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
        Self.sessionAccount(for: authConfiguration)
    }

    // The device metadata key lowercases the username and the ASF device key does not. Existing
    // device records are stored under both keys as they are, so neither may change.
    // Internal rather than private so unit tests can pin the generated keys.
    package func generateDeviceMetadataKey(for username: String) -> String {
            return "\(Self.storeKey(for: authConfiguration)).\(username.lowercased()).\(deviceMetadataKey)"
    }

    // Internal rather than private so unit tests can pin the generated keys.
    package func generateASFDeviceKey(for username: String) -> String {
            return "\(Self.storeKey(for: authConfiguration)).\(username).\(deviceASFKey)"
    }

    private func saveAuthConfiguration(authConfig: AuthConfiguration) {
        if let encodedAuthConfigData = try? Self.encodeAuthConfiguration(authConfig) {
            try? keychain._set(encodedAuthConfigData, key: authConfigurationKey)
        }
    }

    private func getAuthConfiguration() -> AuthConfiguration? {
        if let userPoolConfigData = try? keychain._getData(authConfigurationKey) {
            return try? Self.decodeAuthConfiguration(userPoolConfigData)
        }
        return nil
    }

    /// A test seam: a store over `keychain`, with no access group. Runs the configuration-change
    /// handling the other initializer runs, and none of its access-group handling — so
    /// `userDefaults` and `makeKeychainStore`, which only that handling uses, are never read.
    package init(
        authConfiguration: AuthConfiguration,
        keychain: any KeychainItemStoreBehavior,
        logger: any EngineScopedLogger
    ) {
        self.authConfiguration = authConfiguration
        self.accessGroup = nil
        self.logger = logger
        self.keychain = EngineKeychainStore(keychain, logger: logger)
        self.userDefaults = .standard
        self.makeKeychainStore = { EngineKeychainStore.makeItemStore(service: $0, accessGroup: $1, logger: logger) }
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

    package func retrieveCredential() throws -> AmplifyCredentials {
        let authCredentialStoreKey = generateSessionKey(for: authConfiguration)
        let authCredentialData = try keychain._getData(authCredentialStoreKey)
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

    private func removeSession(for authConfiguration: AuthConfiguration) throws {
        try keychain._remove(generateSessionKey(for: authConfiguration))
    }

}

package extension AWSCognitoAuthCredentialStore {
    /// A keychain store over the item store `makeKeychainStore` builds for `service` and `accessGroup`.
    static func keychainStore(
        _ service: String,
        _ accessGroup: String?,
        _ makeKeychainStore: KeychainStoreFactory,
        logger: any EngineScopedLogger
    ) -> EngineKeychainStore {
        EngineKeychainStore(makeKeychainStore(service, accessGroup), logger: logger)
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
    /// This store's lines, at their pre-M2 category, through the caller's logger.
    var log: EngineLogger {
        logger.scoped(.category("AWSCognitoAuthCredentialStore"))
    }

    /// `KeychainStoreMigrator.log`, its `DefaultLogger` default: the category `KeychainStoreMigrator`, through the
    /// caller's logger.
    var migratorLog: EngineLogger {
        logger.scoped(.category("KeychainStoreMigrator"))
    }
}
