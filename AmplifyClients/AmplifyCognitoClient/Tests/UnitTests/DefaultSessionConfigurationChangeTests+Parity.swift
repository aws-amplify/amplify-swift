//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyFoundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Named sessions under the same changes, and parity with the plugin's own credential store.
extension DefaultSessionConfigurationChangeTests {

    // MARK: - Named sessions

    /// - Given: `.default` and `.named("work")` both signed in under user pool A
    /// - When: both restore under user pool B
    /// - Then:
    ///    - `.default`'s record is deleted; work's record is kept, and work is signed out under B only
    func testNamedSessionUnderTheSameChange_keepsTheOldRecord() async throws {
        let work = ClientFixtures.id("work")
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        var named: AmplifyCognitoClient? = makeClient(ChangeConfigs.both, work)
        scriptSRP("bob")
        scriptIdentityPool()
        _ = try await named?.signIn(username: "bob", password: "password")
        named = nil
        await harness.waitForBaseline()
        let workAccount = SessionRecordKey.account(for: work, in: ChangeConfigs.both.poolNamespace, kind: .session)
        let workRecord = harness.keychain.value(workAccount)

        let defaultThere = await makeClient(ChangeConfigs.otherUserPool).currentSessionState()
        let workThere = await makeClient(ChangeConfigs.otherUserPool, work).currentSessionState()

        XCTAssertEqual(defaultThere, .signedOut)
        XCTAssertEqual(workThere, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNotNil(workRecord)
        XCTAssertEqual(harness.keychain.value(workAccount), workRecord)
    }

    // MARK: - Parity with the plugin

    /// The parity table: the client's rule against the plugin's, on the same inputs.
    ///
    /// - Given: for each pair of configurations, and each seed (a record under the previous account only; under both
    ///   accounts; under neither), two keychains seeded alike
    /// - When: the plugin's store is built with the current configuration over one, and the client's `.default` rule
    ///   runs over the other
    /// - Then:
    ///    - the plugin's items (`amplify.<ns>.session` and `authConfiguration`) are identical in both, by bytes for the
    ///      records and by value for the configuration
    func testParityTable_clientAgainstThePlugin() throws {
        for pair in ChangeConfigs.pairs {
            for seed in ParitySeed.allCases {
                let name = "\(pair.name), \(seed)"
                let pluginSide = TestKeychain()
                let clientSide = TestKeychain()
                for keychain in [pluginSide, clientSide] {
                    seed.apply(previous: pair.previous, current: pair.current, to: keychain)
                }

                _ = AWSCognitoAuthCredentialStore(
                    authConfiguration: pair.current,
                    keychain: pluginSide.itemStore(service: SessionRecordStore.unsharedService),
                    logger: DiscardingEngineLogger()
                )
                let store = clientSide.recordStore(for: SessionStorageNamespace(pools: PoolNamespace(pair.current), accessGroup: nil))
                _ = try store.applyPluginConfigurationRule(current: pair.current)

                XCTAssertEqual(Self.pluginItems(clientSide), Self.pluginItems(pluginSide), name)
                XCTAssertEqual(clientSide.recordedPluginConfiguration(), pluginSide.recordedPluginConfiguration(), name)
                XCTAssertEqual(clientSide.recordedPluginConfiguration(), pair.current, name)
            }
        }
    }

    /// The plugin's store and the client, over one keychain, through each configuration change.
    ///
    /// - Given: one keychain; a guest saved by the plugin under an identity-pool-only configuration, then alice signed
    ///   in by the plugin once a user pool is added
    /// - When: for each configuration of a run of changes (each carried change, the app client alone, and the deleted
    ///   ones), first the plugin then the client starts under it; and, over a second keychain, first the client then
    ///   the plugin
    /// - Then:
    ///    - after each step both see the same login: the plugin's `retrieveCredential()` and the client's `.default`
    ///      hold the same credentials, or both none
    ///    - both orders leave the plugin's items identical
    func testSharedKeychain_pluginAndClientSeeIdenticalState_throughEachChange() async throws {
        let pluginFirst = TestKeychain()
        let clientFirst = TestKeychain()
        let alice = try await signedInPayload("alice", under: ChangeConfigs.both)
        for keychain in [pluginFirst, clientFirst] {
            let store = AWSCognitoAuthCredentialStore(
                authConfiguration: AuthConfiguration(client: ChangeConfigs.identityPoolOnly),
                keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
                logger: DiscardingEngineLogger()
            )
            try store.saveCredential(AmplifyCredentials.decoded(ChangePayloads.guest()))
        }

        for (step, configuration) in ChangeConfigs.run.enumerated() {
            let name = "step \(step): \(configuration.poolNamespace.keyComponent), \(configuration.userPool?.appClientId ?? "-")"
            let pluginSeesFirst = try startPlugin(configuration, over: pluginFirst)
            let clientSeesSecond = try startClient(configuration, over: pluginFirst)
            let clientSeesFirst = try startClient(configuration, over: clientFirst)
            let pluginSeesSecond = try startPlugin(configuration, over: clientFirst)

            XCTAssertEqual(clientSeesSecond, pluginSeesFirst, name)
            XCTAssertEqual(clientSeesFirst, pluginSeesSecond, name)
            XCTAssertEqual(pluginSeesFirst, pluginSeesSecond, name)
            XCTAssertEqual(Self.pluginItems(pluginFirst), Self.pluginItems(clientFirst), name)
            XCTAssertEqual(pluginFirst.recordedPluginConfiguration(), clientFirst.recordedPluginConfiguration(), name)

            if step == 1 {
                // Alice signs in through the plugin once the user pool is added.
                for keychain in [pluginFirst, clientFirst] {
                    let store = AWSCognitoAuthCredentialStore(
                        authConfiguration: AuthConfiguration(client: configuration),
                        keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
                        logger: DiscardingEngineLogger()
                    )
                    try store.saveCredential(AmplifyCredentials.decoded(alice))
                }
            }
        }
    }

    // MARK: Helpers

    /// The plugin started with `configuration` over `keychain`: what it then retrieves.
    private func startPlugin(_ configuration: AuthClientConfiguration, over keychain: TestKeychain) throws -> AmplifyCredentials? {
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: AuthConfiguration(client: configuration),
            keychain: keychain.itemStore(service: SessionRecordStore.unsharedService),
            logger: DiscardingEngineLogger()
        )
        do {
            return try store.retrieveCredential()
        } catch EngineCredentialStoreError.itemNotFound {
            return nil
        }
    }

    /// The client's `.default` started with `configuration` over `keychain`: the rule, then the read.
    private func startClient(_ configuration: AuthClientConfiguration, over keychain: TestKeychain) throws -> AmplifyCredentials? {
        let store = keychain.recordStore(for: SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: nil))
        _ = try store.applyPluginConfigurationRule(current: AuthConfiguration(client: configuration))
        guard case .record(let stored) = try store.read(.default), let credentials = stored.record.credentials else {
            return nil
        }
        return try AmplifyCredentials.decoded(credentials)
    }

    /// The plugin's own items in `keychain`'s plugin service, by account: every item outside the client's
    /// `amplify.1.` family, `authConfiguration` aside, which is compared decoded.
    private static func pluginItems(_ keychain: TestKeychain) -> [String: PluginItem] {
        let store = keychain.itemStore(service: SessionRecordStore.unsharedService)
        let accounts = (try? store.allAccounts()) ?? []
        return Dictionary(uniqueKeysWithValues: accounts
            .filter { !$0.hasPrefix("amplify.1.") && $0 != SessionRecordStore.pluginConfigurationAccount }
            .compactMap { account in keychain.value(account).map { (account, PluginItem($0)) } })
    }
}

// MARK: - Fixtures

/// A plugin item as compared across two keychains: a saved login by its decoded credentials, since two plugin
/// builds may encode the same credentials with their keys in another order; anything else by its bytes.
private enum PluginItem: Equatable {
    case credentials(AmplifyCredentials)
    case bytes(Data)

    init(_ data: Data) {
        if let credentials = try? AmplifyCredentials.decoded(data) {
            self = .credentials(credentials)
        } else {
            self = .bytes(data)
        }
    }
}

/// What a parity row's two keychains start with.
private enum ParitySeed: CaseIterable, CustomStringConvertible {
    /// A record under the previous configuration's account only.
    case previousOnly
    /// A record under each account: the current one's is replaced by a carry.
    case both
    /// No record: nothing is carried or deleted.
    case neither

    var description: String {
        switch self {
        case .previousOnly: return "a record under the previous account"
        case .both: return "a record under each account"
        case .neither: return "no record"
        }
    }

    func apply(previous: AuthConfiguration?, current: AuthConfiguration, to keychain: TestKeychain) {
        if let previous {
            keychain.recordPluginConfiguration(previous)
            if self != .neither {
                keychain.put(Data("previous login".utf8), AWSCognitoAuthCredentialStore.sessionAccount(for: previous))
            }
        }
        if self == .both, AWSCognitoAuthCredentialStore.sessionAccount(for: current) != previous.map(AWSCognitoAuthCredentialStore.sessionAccount) {
            keychain.put(Data("current login".utf8), AWSCognitoAuthCredentialStore.sessionAccount(for: current))
        }
    }
}
