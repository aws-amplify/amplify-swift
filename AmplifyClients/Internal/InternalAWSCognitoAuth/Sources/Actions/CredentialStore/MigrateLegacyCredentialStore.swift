//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable identifier_name
package struct MigrateLegacyCredentialStore: Action {

    package let identifier = "MigrateLegacyCredentialStore"

    /// Legacy Keys
    private let AWSCredentialsProviderClassKey = "AWSCognitoCredentialsProvider"
    private let UserPoolClassKey = "AWSCognitoIdentityUserPool"
    private let AWSCredentialsProviderKeychainAccessKeyId = "accessKey"
    private let AWSCredentialsProviderKeychainSecretAccessKey = "secretKey"
    private let AWSCredentialsProviderKeychainSessionToken = "sessionKey"
    private let AWSCredentialsProviderKeychainExpiration = "expiration"
    private let AWSCredentialsProviderKeychainIdentityId = "identityId"
    private let AWSCognitoIdentityUserPoolCurrentUser = "currentUser"
    private let AWSCognitoIdentityUserDeviceId = "device.id"
    private let AWSCognitoIdentityUserAsfDeviceId = "asf.device.id"
    private let AWSCognitoIdentityUserDeviceSecret = "device.secret"
    private let AWSCognitoIdentityUserDeviceGroup = "device.group"

    private let FederationProviderKey = "federationProvider"
    private let LoginsMapKey = "loginsMap"

    private let AWSCognitoAuthUserPoolCurrentUser = "currentUser"
    private let AWSCognitoAuthUserAccessToken = "accessToken"
    private let AWSCognitoAuthUserIdToken = "idToken"
    private let AWSCognitoAuthUserRefreshToken = "refreshToken"
    private let AWSCognitoAuthUserTokenExpiration = "tokenExpiration"

    package func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        guard let credentialEnvironment = environment as? CredentialEnvironment else {
            let event = CredentialStoreEvent(
                eventType: .throwError(EngineCredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
            return
        }

        let credentialStoreEnvironment = credentialEnvironment.credentialStoreEnvironment
        let authConfiguration = credentialEnvironment.authConfiguration

        let amplifyCredentialStore = credentialStoreEnvironment.amplifyCredentialStoreFactory()

        let migration = LegacyStoreMigration()
        var identityId: String?
        var awsCredentials: EngineAWSCredentials?
        let deviceDetails = getDeviceDetails(
            from: credentialStoreEnvironment,
            with: authConfiguration,
            migration: migration
        )
        let userPoolTokens = migration.read {
            try getUserPoolTokens(
                from: credentialStoreEnvironment,
                with: authConfiguration,
                migration: migration
            )
        }

        // IdentityId and AWSCredentials should exist together
        if let (
            storedIdentityId,
            storedAWSCredentials
        ) = migration.read({
            try getIdentityIdAndAWSCredentials(
                from: credentialStoreEnvironment,
                with: authConfiguration,
                migration: migration
            )
        }) {
            identityId = storedIdentityId
            awsCredentials = storedAWSCredentials
        }
        let loginsMap = getCachedLoginMaps(from: credentialStoreEnvironment, migration: migration)
        let signInMethod = migration.read {
            try getSignInMethod(
                from: credentialStoreEnvironment,
                with: authConfiguration,
                migration: migration
            )
        } ?? .apiBased(.userSRP)

        let hasLegacyValues = deviceDetails != nil || userPoolTokens != nil || identityId != nil
        guard shouldWriteLegacyValuesForward(
            hasLegacyValues: hasLegacyValues,
            migration: migration,
            amplifyCredentialStore: amplifyCredentialStore,
            environment: environment
        ) else {
            await sendLoadCredentialStoreEvent(dispatcher: dispatcher, environment: environment)
            return
        }

        await saveDeviceDetails(deviceDetails, to: amplifyCredentialStore)
        do {
            if let identityId,
               let awsCredentials,
               userPoolTokens == nil {

                if !loginsMap.isEmpty,
                   let providerName = loginsMap.first?.key,
                   let providerToken = loginsMap.first?.value {
                    logVerbose("\(#fileID) Federated signIn", environment: environment)
                    let provider = EngineAuthProvider(identityPoolProviderName: providerName)
                    let credentials = AmplifyCredentials.identityPoolWithFederation(
                        federatedToken: .init(token: providerToken, provider: provider),
                        identityID: identityId,
                        credentials: awsCredentials
                    )
                    try amplifyCredentialStore.saveCredential(credentials)

                } else {
                    logVerbose("\(#fileID) Guest user", environment: environment)
                    let credentials = AmplifyCredentials.identityPoolOnly(
                        identityID: identityId,
                        credentials: awsCredentials
                    )
                    try amplifyCredentialStore.saveCredential(credentials)
                }

            } else if let identityId,
                      let awsCredentials,
                      let userPoolTokens {
                logVerbose("\(#fileID) User pool with identity pool", environment: environment)
                let signedInData = SignedInData(
                    signedInDate: Date.distantPast,
                    signInMethod: signInMethod,
                    cognitoUserPoolTokens: userPoolTokens
                )
                let credentials = AmplifyCredentials.userPoolAndIdentityPool(
                    signedInData: signedInData,
                    identityID: identityId,
                    credentials: awsCredentials
                )
                try amplifyCredentialStore.saveCredential(credentials)

            } else if let userPoolTokens {
                logVerbose("\(#fileID) Only user pool", environment: environment)
                let signedInData = SignedInData(
                    signedInDate: Date.distantPast,
                    signInMethod: signInMethod,
                    cognitoUserPoolTokens: userPoolTokens
                )
                let credentials = AmplifyCredentials.userPoolOnly(signedInData: signedInData)
                try amplifyCredentialStore.saveCredential(credentials)
            }

            // Clean up the old stores, now that their values have been written forward
            migration.clearLegacyStores()

            let event = CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch let error as EngineCredentialStoreError {
            let event = CredentialStoreEvent(eventType: .throwError(error))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        } catch {
            let event = CredentialStoreEvent(
                eventType: .throwError(
                    EngineCredentialStoreError.unknown("An unknown error occurred", error)))
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            await dispatcher.send(event)
        }
    }

    private func getUserPoolTokens(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration,
        migration: LegacyStoreMigration
    ) throws -> EngineUserPoolTokens {

            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let userPoolConfig = authConfiguration.getUserPoolConfiguration()
            else {
                throw EngineCredentialStoreError.configuration(
                    message: AuthPluginErrorConstants.configurationError)
            }

            let serviceKey = "\(bundleIdentifier).\(UserPoolClassKey)"
            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(serviceKey)
            migration.clearAfterMigration(legacyKeychainStore)
            let currentUser = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoAuthUserPoolCurrentUser
                )
            )
            let idToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserIdToken)"
                )
            )
            let accessToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserAccessToken)"
                )
            )
            let refreshToken = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserRefreshToken)"
                )
            )
            let tokenExpirationString = try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: "\(currentUser).\(AWSCognitoAuthUserTokenExpiration)"
                )
            )
            // If the token expiration can't be converted to a date, chose a date in the past
            let pastDate = Date.init(timeIntervalSince1970: 0)
            let tokenExpiration = dateFormatter().date(from: tokenExpirationString) ?? pastDate
            return EngineUserPoolTokens(
                idToken: idToken,
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiration: tokenExpiration
            )
        }

    private func getCachedLoginMaps(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        migration: LegacyStoreMigration
    ) -> [String: String] {

        let serviceKey = "\(String.init(describing: Bundle.main.bundleIdentifier)).AWSMobileClient"
        let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(serviceKey)

        guard let data = migration.read({ try legacyKeychainStore._getData(LoginsMapKey) }) else {
            return [:]
        }

        guard let loginMaps = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return loginMaps
    }

    private func getSignInMethod(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration,
        migration: LegacyStoreMigration
    ) throws -> SignInMethod {

            let serviceKey = "\(String.init(describing: Bundle.main.bundleIdentifier)).AWSMobileClient"
            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(serviceKey)
            migration.clearAfterMigration(legacyKeychainStore)

            let federationProvider = try legacyKeychainStore._getString(FederationProviderKey)
            switch federationProvider {
            case "hostedUI":
                let userPoolConfig = authConfiguration.getUserPoolConfiguration()
                let scopes = userPoolConfig?.hostedUIConfig?.oauth.scopes
                let provider = HostedUIProviderInfo(
                    authProvider: nil,
                    idpIdentifier: nil
                )
                return .hostedUI(.init(
                    scopes: scopes ?? [],
                    providerInfo: provider,
                    presentationAnchor: nil,
                    preferPrivateSession: false,
                    nonce: nil,
                    language: nil,
                    loginHint: nil,
                    prompt: nil,
                    resource: nil
                ))
            default:
                return .apiBased(.userSRP)
            }

        }

    private func userPoolNamespace(
        userPoolConfig: UserPoolConfigurationData,
        for key: String
    ) -> String {
        return "\(userPoolConfig.clientId).\(key)"
    }

    private func userPoolNamespace(
        withUser userName: String,
        userPoolConfig: UserPoolConfigurationData,
        for key: String
    ) -> String {
        return "\(userPoolConfig.poolId).\(userName).\(key)"
    }

    private func getIdentityIdAndAWSCredentials(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration,
        migration: LegacyStoreMigration
    ) throws
    -> (identityId: String, awsCredentials: EngineAWSCredentials) {

        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let identityPoolConfig = authConfiguration.getIdentityPoolConfiguration()
        else {
            throw EngineCredentialStoreError.configuration(
                message: AuthPluginErrorConstants.configurationError)
        }

        let poolId = identityPoolConfig.poolId
        let serviceKey = "\(bundleIdentifier).\(AWSCredentialsProviderClassKey).\(poolId)"
        let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(serviceKey)
        migration.clearAfterMigration(legacyKeychainStore)
        let accessKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainAccessKeyId)
        let secretKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainSecretAccessKey)
        let sessionKey = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainSessionToken)
        let expirationString = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainExpiration)
        let identityId = try legacyKeychainStore._getString(
            AWSCredentialsProviderKeychainIdentityId)

        let awsCredentials = EngineAWSCredentials(
            accessKeyId: accessKey,
            secretAccessKey: secretKey,
            sessionToken: sessionKey,
            expiration: Date(timeIntervalSince1970: Double(expirationString) ?? 0)
        )
        return (identityId, awsCredentials)
    }

    /// UTC, as Amplify's `TimeZone.utc` (`Amplify/Categories/DataStore/Model/Temporal/Temporal.swift`)
    /// builds it: the engine does not import Amplify.
    static let utcTimeZone = TimeZone(abbreviation: "UTC")!

    private func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = Self.utcTimeZone
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return dateFormatter
    }
}

// MARK: - Device details

extension MigrateLegacyCredentialStore {

    private func getDeviceDetails(
        from credentialStoreEnvironment: CredentialStoreEnvironment,
        with authConfiguration: AuthConfiguration,
        migration: LegacyStoreMigration
    ) -> LegacyDeviceDetails? {
            guard let bundleIdentifier = Bundle.main.bundleIdentifier,
                  let userPoolConfig = authConfiguration.getUserPoolConfiguration()
            else {
                return nil
            }

            let serviceKey = "\(bundleIdentifier).\(UserPoolClassKey)"
            let legacyKeychainStore = credentialStoreEnvironment.legacyKeychainStore(serviceKey)

            guard let currentUsername = migration.read({ try legacyKeychainStore._getString(
                userPoolNamespace(
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoIdentityUserPoolCurrentUser
                )
            ) }) else {
                return nil
            }
            let deviceId = migration.read { try legacyKeychainStore._getString(
                userPoolNamespace(
                    withUser: currentUsername,
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoIdentityUserDeviceId
                )
            ) }
            let deviceSecret = migration.read { try legacyKeychainStore._getString(
                userPoolNamespace(
                    withUser: currentUsername,
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoIdentityUserDeviceSecret
                )
            ) }
            let deviceGroup = migration.read { try legacyKeychainStore._getString(
                userPoolNamespace(
                    withUser: currentUsername,
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoIdentityUserDeviceGroup
                )
            ) }
            let asfDeviceId = migration.read { try legacyKeychainStore._getString(
                userPoolNamespace(
                    withUser: currentUsername,
                    userPoolConfig: userPoolConfig,
                    for: AWSCognitoIdentityUserAsfDeviceId
                )
            ) }

            return LegacyDeviceDetails(
                username: currentUsername,
                deviceId: deviceId,
                deviceSecret: deviceSecret,
                deviceGroup: deviceGroup,
                asfDeviceId: asfDeviceId
            )
        }

    private func saveDeviceDetails(
        _ deviceDetails: LegacyDeviceDetails?,
        to amplifyCredentialStore: AmplifyAuthCredentialStoreBehavior
    ) async {
        guard let deviceDetails else {
            return
        }
        if let deviceId = deviceDetails.deviceId,
           let deviceSecret = deviceDetails.deviceSecret,
           let deviceGroup = deviceDetails.deviceGroup {
            let deviceMetaData = DeviceMetadata.metadata(.init(
                deviceKey: deviceId,
                deviceGroupKey: deviceGroup,
                deviceSecret: deviceSecret
            ))
            try? await amplifyCredentialStore.saveDevice(deviceMetaData, for: deviceDetails.username)
        }

        if let asfDeviceId = deviceDetails.asfDeviceId {
            try? await amplifyCredentialStore.saveASFDevice(asfDeviceId, for: deviceDetails.username)
        }
    }
}

// MARK: - Legacy store services

package extension MigrateLegacyCredentialStore {

    /// The keychain services of the legacy stores this migration reads and clears for
    /// `authConfiguration`: the user pool, identity pool and AWSMobileClient stores.
    ///
    /// - Note: These must stay identical to the services the migration reads from. The AWSMobileClient
    ///   service embeds `String(describing:)` of the optional bundle identifier, as the migration does.
    static func legacyServiceKeys(for authConfiguration: AuthConfiguration) -> [String] {
        var serviceKeys: [String] = []
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            if authConfiguration.getUserPoolConfiguration() != nil {
                serviceKeys.append("\(bundleIdentifier).AWSCognitoIdentityUserPool")
            }
            if let identityPoolConfig = authConfiguration.getIdentityPoolConfiguration() {
                serviceKeys.append("\(bundleIdentifier).AWSCognitoCredentialsProvider.\(identityPoolConfig.poolId)")
            }
        }
        serviceKeys.append("\(String(describing: Bundle.main.bundleIdentifier)).AWSMobileClient")
        return serviceKeys
    }
}

// MARK: - Existing session

/// Whether the new credential store already holds a session.
private enum ExistingSession {
    case present
    case absent
    case unreadable(EngineCredentialStoreError)
}

extension MigrateLegacyCredentialStore {

    /// Decides whether the values read from the legacy stores should be written to the new store.
    /// When it returns `false` nothing is migrated, and the legacy stores are either kept for a later
    /// launch or, if they have been superseded, cleared.
    private func shouldWriteLegacyValuesForward(
        hasLegacyValues: Bool,
        migration: LegacyStoreMigration,
        amplifyCredentialStore: AmplifyAuthCredentialStoreBehavior,
        environment: Environment
    ) -> Bool {
        // A read failure only matters if the legacy stores may still hold something.
        migration.discardUnreadableErrorIfLegacyStoresAreEmpty()

        // Without legacy data there is nothing to write over, so the new store is not read.
        guard hasLegacyValues || migration.unreadableError != nil else {
            return true
        }

        switch existingSession(in: amplifyCredentialStore) {
        case .present:
            // The legacy data is older than the session the new store already holds, so writing it
            // forward would replace a newer session. Drop it instead.
            logInfo("\(#fileID) A newer session already exists, discarding legacy credentials", environment: environment)
            migration.clearLegacyStores()
            return false
        case .unreadable(let error):
            // Whether a newer session exists is unknown, so neither migrating nor discarding the
            // legacy data is safe. Keep everything for a later launch.
            logWarn(
                "\(#fileID) Unable to read the credential store, keeping legacy credentials to migrate later: \(error)",
                environment: environment
            )
            return false
        case .absent:
            break
        }

        // A legacy value that exists but could not be read (for example while the device is locked)
        // must not be deleted unmigrated. Keep every legacy store and migrate nothing, so that a later
        // launch migrates the whole legacy session rather than a fragment of it.
        if let unreadableError = migration.unreadableError {
            logWarn(
                "\(#fileID) Unable to read legacy credentials, keeping them to migrate later: \(unreadableError)",
                environment: environment
            )
            return false
        }
        return true
    }

    private func existingSession(in amplifyCredentialStore: AmplifyAuthCredentialStoreBehavior) -> ExistingSession {
        do {
            let credentials = try amplifyCredentialStore.retrieveCredential()
            if case .noCredentials = credentials {
                return .absent
            }
            return .present
        } catch let error as EngineCredentialStoreError {
            if case .securityError = error {
                return .unreadable(error)
            }
            // Missing or undecodable: nothing a migration could overwrite that is still usable.
            return .absent
        } catch {
            return .absent
        }
    }

    private func sendLoadCredentialStoreEvent(dispatcher: EventDispatcher, environment: Environment) async {
        let event = CredentialStoreEvent(eventType: .loadCredentialStore(.amplifyCredentials))
        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }

    private func logWarn(_ message: String, environment: Environment) {
        let logger = (environment as? LoggerProvider)?.logger
        logger?.warn(message)
    }
}

/// Device details read from the legacy user pool store.
private struct LegacyDeviceDetails {
    let username: String
    let deviceId: String?
    let deviceSecret: String?
    let deviceGroup: String?
    let asfDeviceId: String?
}

/// Tracks the reads of a legacy store migration, so that the legacy stores are cleared only once the
/// values they held have been read and written forward.
private final class LegacyStoreMigration {

    /// The first keychain failure other than a missing item, if any. Such a failure means a value may
    /// exist but could not be read, so it cannot be treated as absent.
    private(set) var unreadableError: EngineCredentialStoreError?

    private var storesToClear: [EngineKeychainStore] = []

    /// Performs `read`, returning `nil` if it throws, and records a failure to read a value that may exist.
    func read<T>(_ read: () throws -> T) -> T? {
        do {
            return try read()
        } catch let error as EngineCredentialStoreError {
            if case .securityError = error, unreadableError == nil {
                unreadableError = error
            }
            return nil
        } catch {
            return nil
        }
    }

    /// Forgets a recorded read failure when none of the legacy stores holds any item, so that an app
    /// without legacy data is not held in the keep path by a keychain error it could never recover from.
    /// A store whose contents cannot be determined counts as possibly holding items.
    ///
    /// `errSecInteractionNotAllowed` is never discarded: it is transient (the device is locked), and
    /// whether the keychain reports such items as absent to the `_hasItems()` query is not guaranteed, so
    /// the stores are kept for a later launch whatever that query returns.
    func discardUnreadableErrorIfLegacyStoresAreEmpty() {
        guard let error = unreadableError else {
            return
        }
        if case .securityError(let status) = error, status == errSecInteractionNotAllowed {
            return
        }
        let mayHoldItems = storesToClear.contains { store in
            (try? store._hasItems()) ?? true
        }
        if !mayHoldItems {
            unreadableError = nil
        }
    }

    /// Registers `store` to be cleared once the migration has written its values forward.
    func clearAfterMigration(_ store: EngineKeychainStore) {
        storesToClear.append(store)
    }

    /// Clears every registered legacy store, in the order they were registered.
    func clearLegacyStores() {
        for store in storesToClear {
            try? store._removeAll()
        }
    }
}

extension MigrateLegacyCredentialStore: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension MigrateLegacyCredentialStore: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
// swiftlint:enable identifier_name
