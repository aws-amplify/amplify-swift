//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The plugin's configuration-change rule, extracted as `AWSCognitoAuthCredentialStore.configurationChange(from:to:)`
/// so the Cognito client's `.default` runs the same decision. The extraction changes
/// nothing the plugin does: the decision is each branch's, and the store's `init` issues the same keychain calls, in
/// the same order, as the code before it (kept below as `PreExtractionRule`).
final class AWSCognitoAuthCredentialStoreConfigurationChangeTests: XCTestCase {

    // MARK: - The decision table

    /// Test that the decision is exactly each branch's
    ///
    /// - Given: each `(previous, current)` pair of `ConfigurationChangeCase.table`: no previous; the same; a user pool
    ///   added to an identity-pool-only configuration; an identity pool added, changed or removed under the same user
    ///   pool, app client and region; the user pool changed; the app client changed with the same pools; the app
    ///   client changed with an identity pool added; the identity pool changed with no user pool; and the rest
    /// - When:
    ///    - `configurationChange(from:to:)` decides
    /// - Then:
    ///    - it is `unchanged`, `carry` or `clear`, with the accounts each branch reads, writes or removes
    ///
    func testDecisionTable() {
        for row in ConfigurationChangeCase.table {
            XCTAssertEqual(
                AWSCognitoAuthCredentialStore.configurationChange(from: row.previous, to: row.current),
                row.expected,
                row.name
            )
        }
    }

    /// Test that the store's `init` issues the same keychain calls as before the extraction
    ///
    /// - Given: for each pair of the table, a keychain holding a record under the previous configuration's account, one
    ///   under the current one's, and the previous configuration recorded
    /// - When:
    ///    - the store is built with the current configuration, and, over a copy of the same keychain, the code before
    ///      the extraction runs
    /// - Then:
    ///    - both read the same accounts in the same order, make the same mutations in the same order, and leave the
    ///      same items
    ///
    func testInitIssuesTheSameQueriesAsBefore() throws {
        for row in ConfigurationChangeCase.table {
            let extracted = try Self.seededKeychain(row)
            let before = try Self.seededKeychain(row)

            _ = AWSCognitoAuthCredentialStore(
                authConfiguration: row.current,
                keychain: extracted.store,
                logger: DiscardingEngineLogger()
            )
            PreExtractionRule.run(current: row.current, keychain: EngineKeychainStore(before.store, logger: DiscardingEngineLogger()))

            XCTAssertEqual(extracted.store.readAccounts, before.store.readAccounts, row.name)
            XCTAssertEqual(extracted.keychain.mutations.map(Self.comparable), before.keychain.mutations.map(Self.comparable), row.name)
            for account in ConfigurationChangeCase.accounts {
                XCTAssertEqual(
                    extracted.keychain.value(service: pluginKeychainService, account: account).map { Self.comparable(account, $0) },
                    before.keychain.value(service: pluginKeychainService, account: account).map { Self.comparable(account, $0) },
                    "\(row.name): \(account)"
                )
            }
        }
    }

    /// Test that a configuration the store cannot read is no previous configuration, as before
    ///
    /// - Given: bytes under `authConfiguration` that are not a configuration, and a record under another user pool's
    ///   account
    /// - When:
    ///    - the store is built
    /// - Then:
    ///    - the record is kept, and the current configuration is recorded
    ///
    func testUnreadablePreviousConfigurationIsNone() throws {
        let keychain = InMemoryKeychain()
        let store = InMemoryPluginKeychainStore(keychain: keychain)
        let other = ConfigurationChangeCase.userPool(poolId: "us-east-1_Other")
        let record = Data("alice".utf8)
        try store.set(record, key: AWSCognitoAuthCredentialStore.sessionAccount(for: other))
        try store.set(Data("not a configuration".utf8), key: AWSCognitoAuthCredentialStore.authConfigurationAccount)
        let current = ConfigurationChangeCase.userPool()

        _ = AWSCognitoAuthCredentialStore(authConfiguration: current, keychain: store, logger: DiscardingEngineLogger())

        XCTAssertEqual(try store.getData(AWSCognitoAuthCredentialStore.sessionAccount(for: other)), record)
        XCTAssertEqual(
            try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(store.getData(AWSCognitoAuthCredentialStore.authConfigurationAccount)),
            current
        )
    }

    /// Test that the coder is the store's own
    ///
    /// - Given: a configuration
    /// - When:
    ///    - it is encoded with `encodeAuthConfiguration`, and recorded by a store
    /// - Then:
    ///    - the bytes decode back to it, and equal the store's after decoding; the session account is the store's key
    ///
    func testTheCoderAndTheSessionAccountAreTheStores() throws {
        let configuration = ConfigurationChangeCase.both()
        let keychain = InMemoryKeychain()
        let store = InMemoryPluginKeychainStore(keychain: keychain)
        _ = AWSCognitoAuthCredentialStore(authConfiguration: configuration, keychain: store, logger: DiscardingEngineLogger())

        let encoded = try AWSCognitoAuthCredentialStore.encodeAuthConfiguration(configuration)
        let recorded = try store.getData(AWSCognitoAuthCredentialStore.authConfigurationAccount)

        XCTAssertEqual(try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(encoded), configuration)
        XCTAssertEqual(try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(recorded), configuration)
        XCTAssertEqual(
            AWSCognitoAuthCredentialStore.sessionAccount(for: configuration),
            "amplify.\(ConfigurationChangeCase.userPoolId).\(ConfigurationChangeCase.identityPoolId).session"
        )
        XCTAssertThrowsError(try AWSCognitoAuthCredentialStore.decodeAuthConfiguration(Data("{}".utf8)))
    }

    // MARK: - Helpers

    /// A mutation or an item as two runs are compared: `JSONEncoder` does not fix the order of a configuration's keys,
    /// so `authConfiguration`'s bytes are compared by the configuration they hold.
    private enum Compared: Equatable {
        case write(service: String, account: String, value: Value)
        case other(InMemoryKeychain.Mutation)

        enum Value: Equatable {
            case configuration(AuthConfiguration)
            case bytes(Data)
        }
    }

    private static func comparable(_ mutation: InMemoryKeychain.Mutation) -> Compared {
        guard case .write(let service, let account, let value) = mutation else {
            return .other(mutation)
        }
        return .write(service: service, account: account, value: comparable(account, value))
    }

    private static func comparable(_ account: String, _ value: Data) -> Compared.Value {
        guard account == AWSCognitoAuthCredentialStore.authConfigurationAccount,
              let configuration = try? AWSCognitoAuthCredentialStore.decodeAuthConfiguration(value) else {
            return .bytes(value)
        }
        return .configuration(configuration)
    }

    /// A keychain seeded for `row`: a record under every account of the table, distinct per account, and the previous
    /// configuration recorded. The mutation log starts empty.
    private static func seededKeychain(_ row: ConfigurationChangeCase) throws -> (keychain: InMemoryKeychain, store: InMemoryPluginKeychainStore) {
        let keychain = InMemoryKeychain()
        let store = InMemoryPluginKeychainStore(keychain: keychain)
        for account in ConfigurationChangeCase.accounts where account != AWSCognitoAuthCredentialStore.authConfigurationAccount {
            try store.set(Data("record at \(account)".utf8), key: account)
        }
        if let previous = row.previous {
            try store.set(AWSCognitoAuthCredentialStore.encodeAuthConfiguration(previous), key: AWSCognitoAuthCredentialStore.authConfigurationAccount)
        }
        keychain.resetMutations()
        return (keychain, store)
    }
}

/// One pair of configurations and what the plugin's rule decides for it.
struct ConfigurationChangeCase {
    let name: String
    let previous: AuthConfiguration?
    let current: AuthConfiguration
    let expected: AWSCognitoAuthCredentialStore.ConfigurationChange

    static let userPoolId = "us-east-1_PoolA"
    static let identityPoolId = "us-east-1:00000000-0000-0000-0000-00000000000a"
    static let otherIdentityPoolId = "us-east-1:00000000-0000-0000-0000-00000000000b"

    static func userPool(poolId: String = userPoolId, clientId: String = "client-1", endpoint: String? = nil) -> AuthConfiguration {
        .userPools(userPoolData(poolId: poolId, clientId: clientId, endpoint: endpoint))
    }

    static func identityPool(_ poolId: String = identityPoolId) -> AuthConfiguration {
        .identityPools(IdentityPoolConfigurationData(poolId: poolId, region: "us-east-1"))
    }

    static func both(clientId: String = "client-1", identityPoolId: String = identityPoolId) -> AuthConfiguration {
        .userPoolsAndIdentityPools(
            userPoolData(clientId: clientId),
            IdentityPoolConfigurationData(poolId: identityPoolId, region: "us-east-1")
        )
    }

    private static func userPoolData(poolId: String = userPoolId, clientId: String = "client-1", endpoint: String? = nil) -> UserPoolConfigurationData {
        UserPoolConfigurationData(
            poolId: poolId,
            clientId: clientId,
            region: "us-east-1",
            endpoint: endpoint.map { UserPoolConfigurationData.CustomEndpoint(validatedHost: $0) }
        )
    }

    private static func account(_ configuration: AuthConfiguration) -> String {
        AWSCognitoAuthCredentialStore.sessionAccount(for: configuration)
    }

    /// Every account the table's configurations name, and `authConfiguration`.
    static var accounts: [String] {
        Set(table.flatMap { [$0.previous, $0.current].compactMap { $0 }.map(account) })
            .union([AWSCognitoAuthCredentialStore.authConfigurationAccount])
            .sorted()
    }

    static let table: [ConfigurationChangeCase] = [
        .init(name: "first run", previous: nil, current: both(), expected: .unchanged),
        .init(name: "same, both pools", previous: both(), current: both(), expected: .unchanged),
        .init(name: "same, user pool only", previous: userPool(), current: userPool(), expected: .unchanged),
        .init(
            name: "same, identity pool only (the plugin copies the record over itself)",
            previous: identityPool(), current: identityPool(),
            expected: .carry(fromAccount: account(identityPool()), toAccount: account(identityPool()))
        ),
        .init(
            name: "user pool added to identity-pool-only",
            previous: identityPool(), current: both(),
            expected: .carry(fromAccount: account(identityPool()), toAccount: account(both()))
        ),
        .init(
            name: "identity pool added under the same user pool",
            previous: userPool(), current: both(),
            expected: .carry(fromAccount: account(userPool()), toAccount: account(both()))
        ),
        .init(
            name: "identity pool changed under the same user pool",
            previous: both(), current: both(identityPoolId: otherIdentityPoolId),
            expected: .carry(fromAccount: account(both()), toAccount: account(both(identityPoolId: otherIdentityPoolId)))
        ),
        .init(
            name: "identity pool removed under the same user pool",
            previous: both(), current: userPool(),
            expected: .carry(fromAccount: account(both()), toAccount: account(userPool()))
        ),
        .init(
            name: "a change outside the key (a custom endpoint, as a Gen1 configuration has)",
            previous: userPool(endpoint: "auth.example.com"), current: userPool(),
            expected: .carry(fromAccount: account(userPool()), toAccount: account(userPool()))
        ),
        .init(
            name: "user pool changed",
            previous: userPool(), current: userPool(poolId: "us-east-1_PoolB"),
            expected: .clear(account: account(userPool()), previous: userPool())
        ),
        .init(name: "app client changed with the same pools", previous: both(), current: both(clientId: "client-2"), expected: .unchanged),
        .init(
            name: "app client changed with the same user pool only",
            previous: userPool(), current: userPool(clientId: "client-2"), expected: .unchanged
        ),
        .init(
            name: "app client changed with an identity pool added",
            previous: userPool(), current: both(clientId: "client-2"),
            expected: .clear(account: account(userPool()), previous: userPool())
        ),
        .init(
            name: "identity pool changed with no user pool",
            previous: identityPool(), current: identityPool(otherIdentityPoolId),
            expected: .clear(account: account(identityPool()), previous: identityPool())
        ),
        .init(
            name: "user pool removed, the identity pool kept",
            previous: both(), current: identityPool(),
            expected: .clear(account: account(both()), previous: both())
        ),
        .init(
            name: "identity pool replaced by a user pool",
            previous: identityPool(), current: userPool(),
            expected: .clear(account: account(identityPool()), previous: identityPool())
        ),
        .init(
            name: "user pool added to identity-pool-only, with another identity pool",
            previous: identityPool(), current: both(identityPoolId: otherIdentityPoolId),
            expected: .clear(account: account(identityPool()), previous: identityPool())
        )
    ]
}

/// `restoreCredentialsOnConfigurationChanges` then `saveAuthConfiguration`, as the store's `init` called them, with
/// `getAuthConfiguration`, `removeSession`, `storeKey` and the account names, as they were before the decision was
/// extracted, verbatim apart from their receivers: the reference the extracted code must reproduce, independent of it.
private enum PreExtractionRule {

    private static let authConfigurationKey = "authConfiguration"
    private static let sessionKey = "session"

    private static func storeKey(for authConfiguration: AuthConfiguration) -> String {
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

    private static func generateSessionKey(for authConfiguration: AuthConfiguration) -> String {
        "\(storeKey(for: authConfiguration)).\(sessionKey)"
    }

    static func run(current currentAuthConfig: AuthConfiguration, keychain: EngineKeychainStore) {
        restoreCredentialsOnConfigurationChanges(currentAuthConfig: currentAuthConfig, keychain: keychain)
        // saveAuthConfiguration
        if let encodedAuthConfigData = try? JSONEncoder().encode(currentAuthConfig) {
            try? keychain._set(encodedAuthConfigData, key: authConfigurationKey)
        }
    }

    private static func restoreCredentialsOnConfigurationChanges(currentAuthConfig: AuthConfiguration, keychain: EngineKeychainStore) {
        guard let oldAuthConfigData = getAuthConfiguration(keychain) else {
            return
        }
        let oldNameSpace = generateSessionKey(for: oldAuthConfigData)
        let newNameSpace = generateSessionKey(for: currentAuthConfig)

        let oldUserPoolConfiguration = oldAuthConfigData.getUserPoolConfiguration()
        let oldIdentityPoolConfiguration = oldAuthConfigData.getIdentityPoolConfiguration()
        let newIdentityConfigData = currentAuthConfig.getIdentityPoolConfiguration()
        let newUserPoolConfiguration = currentAuthConfig.getUserPoolConfiguration()

        if oldUserPoolConfiguration == nil &&
            newIdentityConfigData != nil &&
            oldIdentityPoolConfiguration == newIdentityConfigData {
            if let oldCognitoCredentialsData = try? keychain._getData(oldNameSpace) {
                try? keychain._set(oldCognitoCredentialsData, key: newNameSpace)
            }
        } else if oldAuthConfigData != currentAuthConfig &&
                    oldUserPoolConfiguration != nil &&
                    UserPoolConfigurationData.isNamespacingEqual(
                        lhs: oldUserPoolConfiguration,
                        rhs: newUserPoolConfiguration
                    ) {
            if let oldCognitoCredentialsData = try? keychain._getData(oldNameSpace) {
                try? keychain._set(oldCognitoCredentialsData, key: newNameSpace)
            }
        } else if oldAuthConfigData != currentAuthConfig &&
                    oldNameSpace != newNameSpace {
            try? keychain._remove(generateSessionKey(for: oldAuthConfigData))
        }
    }

    private static func getAuthConfiguration(_ keychain: EngineKeychainStore) -> AuthConfiguration? {
        if let userPoolConfigData = try? keychain._getData(authConfigurationKey) {
            return try? JSONDecoder().decode(AuthConfiguration.self, from: userPoolConfigData)
        }
        return nil
    }
}
