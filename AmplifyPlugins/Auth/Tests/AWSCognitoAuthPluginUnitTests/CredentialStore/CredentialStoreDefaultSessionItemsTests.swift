//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The Cognito client's two default-session items under the plugin's configuration-change rule.
///
/// The client's `.default` shares the plugin's saved login, and keeps two items beside it that describe that login:
/// `amplify.1.<pools>.$default.meta` (its label and last user) and `amplify.1.<pools>.$default.challenge` (its
/// unfinished sign-in). When the plugin deletes the old configuration's login (a clear), it removes the old
/// namespace's two items too, as the client does on the same change; on a carry, or no change, it removes nothing.
final class CredentialStoreDefaultSessionItemsTests: XCTestCase {

    private static let previous = ConfigurationChangeCase.userPool()
    private static let current = ConfigurationChangeCase.userPool(poolId: "us-east-1_PoolB")

    // MARK: - The clear

    /// Test that a clear removes the old namespace's two default-session items, and nothing else of the client's
    ///
    /// - Given: the plugin's login under user pool A, recorded as the last configuration; the client's `$default.meta`
    ///   and `$default.challenge` under A, under user pool B, and under A with an identity pool (a namespace that
    ///   begins with A's); a named session's record and interrupted sign-in under A; and a development build's
    ///   leftover `$default.session` under A
    /// - When:
    ///    - the plugin's store starts under user pool B
    /// - Then:
    ///    - A's login is deleted, and so are A's `$default.meta` and `$default.challenge`
    ///    - every other item is left as it was
    ///    - the removals come right after the login's, before the configuration is recorded
    ///
    func testClear_removesTheOldNamespacesDefaultSessionItems() throws {
        let (keychain, store) = try Self.seeded(previous: Self.previous)
        let removed = Self.defaultSessionItems(of: Self.previous)
        let kept = Self.clientItems.filter { !removed.contains($0) }

        _ = AWSCognitoAuthCredentialStore(authConfiguration: Self.current, keychain: store, logger: DiscardingEngineLogger())

        XCTAssertNil(keychain.value(service: pluginKeychainService, account: AWSCognitoAuthCredentialStore.sessionAccount(for: Self.previous)))
        for account in removed {
            XCTAssertNil(keychain.value(service: pluginKeychainService, account: account), account)
        }
        for account in kept {
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: account), Self.value(account), account)
        }
        XCTAssertEqual(Array(keychain.mutations.prefix(3)), [
            .remove(service: pluginKeychainService, account: AWSCognitoAuthCredentialStore.sessionAccount(for: Self.previous)),
            .remove(service: pluginKeychainService, account: removed[0]),
            .remove(service: pluginKeychainService, account: removed[1])
        ])
        XCTAssertEqual(keychain.mutations.count, 4, "then only the configuration is recorded")
    }

    /// Test that a clear whose login could not be deleted keeps the two items, which still describe it
    ///
    /// - Given: the same keychain, with the removal of A's login failing with `errSecInteractionNotAllowed`
    /// - When:
    ///    - the plugin's store starts under user pool B
    /// - Then:
    ///    - A's login, `$default.meta` and `$default.challenge` are all still there
    ///
    func testClear_whoseLoginRemovalFails_keepsTheItems() throws {
        let (keychain, store) = try Self.seeded(previous: Self.previous)
        keychain.failing(
            .remove,
            with: errSecInteractionNotAllowed,
            forAccount: AWSCognitoAuthCredentialStore.sessionAccount(for: Self.previous)
        )

        _ = AWSCognitoAuthCredentialStore(authConfiguration: Self.current, keychain: store, logger: DiscardingEngineLogger())

        XCTAssertNotNil(keychain.value(service: pluginKeychainService, account: AWSCognitoAuthCredentialStore.sessionAccount(for: Self.previous)))
        for account in Self.clientItems {
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: account), Self.value(account), account)
        }
    }

    /// Test that a clear whose old login is already gone still removes the two items
    ///
    /// - Given: the same keychain, but with no plugin login under user pool A (already deleted, so its removal finds
    ///   nothing), and A still recorded as the last configuration
    /// - When:
    ///    - the plugin's store starts under user pool B
    /// - Then:
    ///    - A's `$default.meta` and `$default.challenge` are removed, right after the login's removal
    ///    - every other client item is left as it was
    ///
    func testClear_whoseLoginIsAlreadyAbsent_stillRemovesTheItems() throws {
        let (keychain, store) = try Self.seeded(previous: Self.previous)
        let loginAccount = AWSCognitoAuthCredentialStore.sessionAccount(for: Self.previous)
        try store.remove(loginAccount)
        XCTAssertNil(keychain.value(service: pluginKeychainService, account: loginAccount))
        keychain.resetMutations()
        let removed = Self.defaultSessionItems(of: Self.previous)

        _ = AWSCognitoAuthCredentialStore(authConfiguration: Self.current, keychain: store, logger: DiscardingEngineLogger())

        for account in removed {
            XCTAssertNil(keychain.value(service: pluginKeychainService, account: account), account)
        }
        for account in Self.clientItems where !removed.contains(account) {
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: account), Self.value(account), account)
        }
        XCTAssertEqual(Array(keychain.mutations.prefix(3)), [
            .remove(service: pluginKeychainService, account: loginAccount),
            .remove(service: pluginKeychainService, account: removed[0]),
            .remove(service: pluginKeychainService, account: removed[1])
        ])
    }

    // MARK: - The carry

    /// Test that a carry keeps the old namespace's two default-session items, as it keeps the old login
    ///
    /// - Given: the same keychain, under user pool A with no identity pool
    /// - When:
    ///    - the plugin's store starts under user pool A with an identity pool added (a carry)
    /// - Then:
    ///    - A's login is kept and copied to the new namespace
    ///    - every client item is left as it was, and none is removed
    ///
    func testCarry_keepsTheOldNamespacesDefaultSessionItems() throws {
        let (keychain, store) = try Self.seeded(previous: Self.previous)
        let carried = ConfigurationChangeCase.both()

        _ = AWSCognitoAuthCredentialStore(authConfiguration: carried, keychain: store, logger: DiscardingEngineLogger())

        for configuration in [Self.previous, carried] {
            let account = AWSCognitoAuthCredentialStore.sessionAccount(for: configuration)
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: account), Data("login".utf8), account)
        }
        for account in Self.clientItems {
            XCTAssertEqual(keychain.value(service: pluginKeychainService, account: account), Self.value(account), account)
        }
        XCTAssertFalse(keychain.mutations.contains { mutation in
            if case .remove = mutation { return true }
            return false
        })
    }

    // MARK: - Every change

    /// Test that only a clear removes default-session items, and only the previous configuration's
    ///
    /// - Given: for each pair of `ConfigurationChangeCase.table`, a keychain holding the plugin's login under the
    ///   previous configuration, recorded as the last one; the client's `$default.meta` and `$default.challenge` under
    ///   every namespace the table names; and a named session's record and interrupted sign-in under each
    /// - When:
    ///    - the plugin's store starts under the current configuration
    /// - Then:
    ///    - on a clear, exactly the previous namespace's `$default.meta` and `$default.challenge` are removed
    ///    - on a carry, or no change, no client item is removed
    ///
    func testOnlyAClearRemovesDefaultSessionItems_andOnlyThePreviousNamespaces() throws {
        let namespaces = Set(ConfigurationChangeCase.table.flatMap { [$0.previous, $0.current].compactMap { $0 } }
            .map(AWSCognitoAuthCredentialStore.poolNamespace(of:)))
        for row in ConfigurationChangeCase.table {
            let keychain = InMemoryKeychain()
            let store = InMemoryPluginKeychainStore(keychain: keychain)
            if let previous = row.previous {
                try store.set(Data("login".utf8), key: AWSCognitoAuthCredentialStore.sessionAccount(for: previous))
                try store.set(
                    AWSCognitoAuthCredentialStore.encodeAuthConfiguration(previous),
                    key: AWSCognitoAuthCredentialStore.authConfigurationAccount
                )
            }
            let clientItems = namespaces.flatMap { namespace in
                SessionRecordAccount.defaultSessionItemAccounts(poolNamespace: namespace)
                    + ["amplify.1.\(namespace).work.session", "amplify.1.\(namespace).work.challenge"]
            }
            for account in clientItems {
                try store.set(Self.value(account), key: account)
            }
            keychain.resetMutations()

            _ = AWSCognitoAuthCredentialStore(authConfiguration: row.current, keychain: store, logger: DiscardingEngineLogger())

            let expected: Set<String>
            if case .clear(_, let previous) = row.expected {
                expected = Set(Self.defaultSessionItems(of: previous))
            } else {
                expected = []
            }
            let removed = Set(clientItems.filter { keychain.value(service: pluginKeychainService, account: $0) == nil })
            XCTAssertEqual(removed, expected, row.name)
            let removals = keychain.mutations.compactMap { mutation -> String? in
                guard case .remove(_, let account) = mutation, SessionRecordAccount.isClientSessionRecord(account) else {
                    return nil
                }
                return account
            }
            XCTAssertEqual(Set(removals), expected, row.name)
            XCTAssertEqual(removals.count, expected.count, row.name)
        }
    }

    // MARK: - The accounts

    /// Test that the plugin names the two items exactly as the Cognito client does
    ///
    /// - Given: a user-pool-only, an identity-pool-only, and a two-pool configuration
    /// - When:
    ///    - the plugin builds the accounts of the old namespace's two items, and the client builds its sidecar and
    ///      interrupted-sign-in accounts for `.default` under the same configuration
    /// - Then:
    ///    - they are the same two accounts, in the same order: the sidecar, then the interrupted sign-in
    ///    - the plugin's pools part is the client's namespace component, and its session account the client's
    ///
    func testTheAccountsAreTheClients() {
        let configurations = [
            ConfigurationChangeCase.userPool(),
            ConfigurationChangeCase.identityPool(),
            ConfigurationChangeCase.both()
        ]
        for configuration in configurations {
            let pools = PoolNamespace(configuration)
            XCTAssertEqual(AWSCognitoAuthCredentialStore.poolNamespace(of: configuration), pools.keyComponent)
            XCTAssertEqual(AWSCognitoAuthCredentialStore.sessionAccount(for: configuration), SessionRecordKey.pluginSessionAccount(in: pools))
            XCTAssertEqual(Self.defaultSessionItems(of: configuration), [
                SessionRecordKey.metaAccount(in: pools),
                SessionRecordKey.account(for: .default, in: pools, kind: .challenge)
            ])
        }
        XCTAssertEqual(
            Self.defaultSessionItems(of: ConfigurationChangeCase.both()),
            [
                "amplify.1.\(ConfigurationChangeCase.userPoolId).\(ConfigurationChangeCase.identityPoolId).$default.meta",
                "amplify.1.\(ConfigurationChangeCase.userPoolId).\(ConfigurationChangeCase.identityPoolId).$default.challenge"
            ]
        )
    }

    // MARK: - Helpers

    private static func defaultSessionItems(of configuration: AuthConfiguration) -> [String] {
        SessionRecordAccount.defaultSessionItemAccounts(poolNamespace: AWSCognitoAuthCredentialStore.poolNamespace(of: configuration))
    }

    /// The client items `seeded(previous:)` writes beside the plugin's login, distinct per account.
    private static var clientItems: [String] {
        let poolA = ConfigurationChangeCase.userPoolId
        return defaultSessionItems(of: previous)
            + defaultSessionItems(of: current)
            + defaultSessionItems(of: ConfigurationChangeCase.both())
            + ["amplify.1.\(poolA).work.session", "amplify.1.\(poolA).work.challenge", "amplify.1.\(poolA).$default.session"]
    }

    private static func value(_ account: String) -> Data {
        Data("item at \(account)".utf8)
    }

    /// A keychain holding the plugin's login under `previous`, recorded as the last configuration, and every one of
    /// `clientItems`. The mutation log starts empty.
    private static func seeded(previous: AuthConfiguration) throws -> (InMemoryKeychain, InMemoryPluginKeychainStore) {
        let keychain = InMemoryKeychain()
        let store = InMemoryPluginKeychainStore(keychain: keychain)
        try store.set(Data("login".utf8), key: AWSCognitoAuthCredentialStore.sessionAccount(for: previous))
        try store.set(
            AWSCognitoAuthCredentialStore.encodeAuthConfiguration(previous),
            key: AWSCognitoAuthCredentialStore.authConfigurationAccount
        )
        for account in clientItems {
            try store.set(value(account), key: account)
        }
        keychain.resetMutations()
        return (keychain, store)
    }
}
