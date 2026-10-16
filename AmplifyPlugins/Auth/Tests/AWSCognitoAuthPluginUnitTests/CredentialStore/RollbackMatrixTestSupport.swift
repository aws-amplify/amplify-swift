//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The unshared service the plugin and the Cognito client both store their records under.
let pluginKeychainService = "com.amplify.awsCognitoAuthPlugin"

/// The plugin's keychain item store over the shared in-memory keychain fake, so that the plugin's
/// credential store and the Cognito client's real record store can run over one keychain.
///
/// Records every read that reaches it, and, through `RollbackPluginBinary.keychainStore(over:)`, every read of a
/// Cognito client record by either plugin binary. Only plugin binaries read through this store: the client's half of a
/// row uses the keychain directly.
final class InMemoryPluginKeychainStore: KeychainItemStoreBehavior, @unchecked Sendable {

    let keychain: InMemoryKeychain
    private let itemStore: InMemoryKeychainItemStore

    // `@unchecked Sendable`: the three properties below are only touched while holding `lock`.
    private let lock = NSLock()
    private var recordedReads: [String] = []
    private var recordedHiddenReads: [String] = []
    private var recordedHiddenRemoves: [String] = []

    init(keychain: InMemoryKeychain, service: String = pluginKeychainService) {
        self.keychain = keychain
        self.itemStore = keychain.store(service: service)
    }

    /// Every account read so far, in order. A read the `.released` binary refused never reaches this store, so it is
    /// not here, only in `hiddenReadAccounts`.
    var readAccounts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedReads
    }

    /// Every hidden account (a Cognito client record, `amplify.<digits>.…`) a plugin binary asked to read through
    /// `RollbackPluginBinary.keychainStore(over:)`, in order, whether its view refused it (`.released`) or read it
    /// (`.current`). Empty unless a plugin reads a client record, so the rows' "no plugin reads a client record"
    /// assertions are made on this, which can fail for either binary.
    var hiddenReadAccounts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedHiddenReads
    }

    /// Records a plugin binary's read of a hidden account.
    func recordHiddenRead(_ account: String) {
        lock.lock()
        defer { lock.unlock() }
        recordedHiddenReads.append(account)
    }

    /// Every hidden account a plugin binary asked to remove by its account through
    /// `RollbackPluginBinary.keychainStore(over:)`, in order, whether its view kept it (`.released`) or removed it
    /// (`.current`). `removeAll()` is not here.
    var hiddenRemoveAccounts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recordedHiddenRemoves
    }

    /// Records a plugin binary's removal of a hidden account.
    func recordHiddenRemove(_ account: String) {
        lock.lock()
        defer { lock.unlock() }
        recordedHiddenRemoves.append(account)
    }

    func getData(_ key: String) throws -> Data {
        lock.lock()
        recordedReads.append(key)
        lock.unlock()
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

    /// The accounts under the client's schema-1 prefix that a write or removal touched.
    var mutatedClientAccounts: [String] {
        mutatedAccounts.filter { $0.hasPrefix("amplify.1.") }
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

/// The plugin binaries a rollback can land on, as the columns of the rollback matrix name them.
///
/// Both run this plugin's credential store, so on every read, save, delete and refresh path they run identical code,
/// and the stored-format goldens (G2) pin what both store. On those paths this plugin's store touches only its own
/// key, as 2.62.0's does, with one exception: on a configuration change that deletes the old login, `.current` also
/// removes the old namespace's two `$default` items (the client's `$default.meta` and `$default.challenge`), and
/// `.released` doesn't, since 2.62.0 never removes a client record outside a service-wide removal. They differ in what
/// they can see and remove (`PluginBinaryKeychainView`, which refuses `.released` any read of a client record and
/// keeps every client record it asks to remove) and in the access-group transition, which the test seam skips: a row
/// that needs it runs 2.62.0's service-wide `_removeAll()` as `removeAll()` on the `.released` view, and this
/// plugin's scoped wipe for `.current`. The access-group migration (`migrateKeychainItemsOfUserSession: true`) is not
/// emulated for `.released`.
enum RollbackPluginBinary: String, CaseIterable {
    /// A released plugin (2.62.0), which does not know the Cognito client's records.
    case released
    /// This plugin, over the whole keychain. It no longer reads the client's records either.
    case current

    /// The keychain as this binary sees it, over `pluginKeychain`: every read of a client record is recorded in
    /// `hiddenReadAccounts`, and for `.released` answers "no item"; every removal of one is recorded in
    /// `hiddenRemoveAccounts`, and for `.released` does nothing.
    func keychainStore(over pluginKeychain: InMemoryPluginKeychainStore) -> any KeychainItemStoreBehavior {
        PluginBinaryKeychainView(
            base: pluginKeychain,
            hidesClientRecords: self == .released,
            onClientRecordRead: { pluginKeychain.recordHiddenRead($0) },
            onClientRecordRemove: { pluginKeychain.recordHiddenRemove($0) }
        )
    }
}
