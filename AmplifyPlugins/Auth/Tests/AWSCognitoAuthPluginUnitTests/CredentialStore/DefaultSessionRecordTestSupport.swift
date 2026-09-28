//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
@_spi(KeychainStore) import AWSPluginsCore
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
import InternalAWSCognitoAuth

/// The unshared service the plugin and the Cognito client both store their records under.
let pluginKeychainService = "com.amplify.awsCognitoAuthPlugin"

/// The plugin's keychain item store over the shared in-memory keychain fake, so that the plugin's
/// credential store and the Cognito client's real record store can run over one keychain.
///
/// Records every read, and can fail reads of one account as the real keychain does
/// (`KeychainAccessError.securityError`), which the credential store maps as it maps any keychain failure.
final class InMemoryPluginKeychainStore: KeychainItemStoreBehavior, @unchecked Sendable {

    let keychain: InMemoryKeychain
    private let itemStore: InMemoryKeychainItemStore

    // `@unchecked Sendable`: the two properties below are only touched while holding `lock`.
    private let lock = NSLock()
    private var recordedReads: [String] = []
    private var readFailures: [String: OSStatus] = [:]

    init(keychain: InMemoryKeychain, service: String = pluginKeychainService) {
        self.keychain = keychain
        self.itemStore = keychain.store(service: service)
    }

    /// Every account read so far, in order.
    var readAccounts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedReads
    }

    /// Makes every read of `account` fail with `status` until `clearReadFailures()`.
    func failReads(of account: String, with status: OSStatus) {
        lock.lock()
        defer { lock.unlock() }
        readFailures[account] = status
    }

    func clearReadFailures() {
        lock.lock()
        defer { lock.unlock() }
        readFailures.removeAll()
    }

    func getData(_ key: String) throws -> Data {
        let failure: OSStatus? = {
            lock.lock()
            defer { lock.unlock() }
            recordedReads.append(key)
            return readFailures[key]
        }()
        if let failure {
            throw KeychainAccessError.securityError(failure)
        }
        return try itemStore.getData(key)
    }

    func set(_ value: Data, key: String) throws {
        try itemStore.set(value, key: key)
    }

    func addIfAbsent(_ value: Data, key: String) throws -> Bool {
        try itemStore.addIfAbsent(value, key: key)
    }

    func replaceIfPresent(_ value: Data, key: String) throws -> Bool {
        try itemStore.replaceIfPresent(value, key: key)
    }

    func move(_ key: String, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try itemStore.move(key, to: destination)
    }

    func move(_ entry: KeychainEntry, to destination: KeychainItemAttributes) throws -> KeychainMoveOutcome {
        try itemStore.move(entry, to: destination)
    }

    func remove(_ key: String) throws {
        try itemStore.remove(key)
    }

    func remove(_ entry: KeychainEntry) throws {
        try itemStore.remove(entry)
    }

    func removeAll() throws {
        try itemStore.removeAll()
    }

    func hasItems() throws -> Bool {
        try itemStore.hasItems()
    }

    func allAccounts() throws -> [String] {
        try itemStore.allAccounts()
    }

    func allEntries() throws -> [KeychainEntry] {
        try itemStore.allEntries()
    }
}

extension InMemoryKeychain {

    /// Every account a write, removal or move touched, in order.
    var mutatedAccounts: [String] {
        mutations.compactMap { mutation in
            switch mutation {
            case .write(_, let account, _), .remove(_, let account), .move(_, let account, _):
                return account
            case .removeAll:
                return nil
            }
        }
    }

    /// Whether anything was ever removed service-wide, which would reach every `amplify.1.` record.
    var hasRemovedAll: Bool {
        mutations.contains { mutation in
            if case .removeAll = mutation { return true }
            return false
        }
    }

    /// The accounts under the client's schema-1 prefix that a write or removal touched.
    var mutatedClientAccounts: [String] {
        mutatedAccounts.filter { $0.hasPrefix("amplify.1.") }
    }
}

/// Session records written by the Cognito client's own storage code, not by hand, so the plugin's
/// reader is tested against exactly what the client writes.
///
/// Each helper that changes the keychain clears its mutation log afterwards, so the log holds only what
/// the plugin does from then on.
enum CognitoClientRecords {

    /// The client's account for its default session in `authConfiguration`'s pools.
    static func defaultSessionAccount(for authConfiguration: AuthConfiguration) -> String {
        SessionRecordKey.account(for: .default, in: poolNamespace(for: authConfiguration), kind: .session)
    }

    /// Signs `credentials` in under the client's default session, through the client's record store.
    ///
    /// - Returns: The bytes the client stored.
    @discardableResult
    static func writeDefaultSession(
        _ credentials: AmplifyCredentials,
        label: String? = "Work",
        in keychain: InMemoryKeychain,
        for authConfiguration: AuthConfiguration
    ) throws -> Data {
        let store = recordStore(in: keychain, for: authConfiguration)
        let record = try SessionRecord(
            label: label,
            username: username(of: credentials),
            kind: kind(of: credentials),
            credentials: JSONEncoder().encode(credentials)
        )
        let outcome = try store.write(record, for: .default, expecting: nil)
        guard outcome.didCommit else {
            throw CocoaError(.fileWriteFileExists)
        }
        keychain.resetMutations()
        return try storedBytes(in: keychain, for: authConfiguration)
    }

    /// Signs the client's default session out, through the client's record store: the row is kept with
    /// no credentials, and the plugin's record is deleted.
    static func signOutDefaultSession(in keychain: InMemoryKeychain, for authConfiguration: AuthConfiguration) throws {
        _ = try recordStore(in: keychain, for: authConfiguration).signOut(.default)
        keychain.resetMutations()
    }

    /// The bytes currently stored under the client's default-session account.
    static func storedBytes(in keychain: InMemoryKeychain, for authConfiguration: AuthConfiguration) throws -> Data {
        guard let data = keychain.value(service: pluginKeychainService, account: defaultSessionAccount(for: authConfiguration)) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return data
    }

    private static func recordStore(in keychain: InMemoryKeychain, for authConfiguration: AuthConfiguration) -> SessionRecordStore {
        SessionRecordStore(
            namespace: SessionStorageNamespace(pools: poolNamespace(for: authConfiguration), accessGroup: nil),
            keychain: keychain.store(service: SessionRecordStore.unsharedService)
        )
    }

    private static func poolNamespace(for authConfiguration: AuthConfiguration) -> PoolNamespace {
        switch authConfiguration {
        case .userPools(let userPool):
            return .userPool(userPool.poolId)
        case .identityPools(let identityPool):
            return .identityPool(identityPool.poolId)
        case .userPoolsAndIdentityPools(let userPool, let identityPool):
            return .userPoolAndIdentityPool(userPoolId: userPool.poolId, identityPoolId: identityPool.poolId)
        }
    }

    private static func kind(of credentials: AmplifyCredentials) -> SessionKind {
        switch credentials {
        case .userPoolOnly:
            return .userPoolOnly
        case .userPoolAndIdentityPool:
            return .userPoolAndIdentityPool
        case .identityPoolOnly:
            return .guest
        case .identityPoolWithFederation:
            return .federated
        case .noCredentials:
            return .signedOut
        }
    }

    private static func username(of credentials: AmplifyCredentials) -> String? {
        switch credentials {
        case .userPoolOnly(let signedInData), .userPoolAndIdentityPool(let signedInData, _, _):
            return signedInData.username
        case .identityPoolOnly, .identityPoolWithFederation, .noCredentials:
            return nil
        }
    }
}

/// Credentials that stay valid for the length of any test, so no read of them triggers a refresh.
enum LongLivedCredentials {

    static func tokens(username: String = "alice", sub: String = "alice-sub") -> EngineUserPoolTokens {
        let expiry = String(Date(timeIntervalSinceNow: 3_600).timeIntervalSince1970)
        let claims = ["sub": sub, "username": username, "iat": "1516239022", "exp": expiry]
        return EngineUserPoolTokens(
            idToken: CognitoAuthTestHelper.buildToken(for: claims),
            accessToken: CognitoAuthTestHelper.buildToken(for: claims),
            refreshToken: "refresh-\(username)",
            expiresIn: 3_600
        )
    }

    static func awsCredentials() -> EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "clientAccessKey",
            secretAccessKey: "clientSecretKey",
            sessionToken: "clientSessionToken",
            expiration: Date(timeIntervalSinceNow: 3_600)
        )
    }

    static func userPoolAndIdentityPool(username: String = "alice") -> AmplifyCredentials {
        .userPoolAndIdentityPool(
            signedInData: SignedInData(
                signedInDate: Date(),
                signInMethod: .apiBased(.userSRP),
                cognitoUserPoolTokens: tokens(username: username)
            ),
            identityID: "client-identity-id",
            credentials: awsCredentials()
        )
    }
}
