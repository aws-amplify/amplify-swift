//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import InternalAmplifyKeychain
import XCTest
@testable import Amplify
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The sign-out rows of the rollback matrix, the plugin's side, beside `RollbackMatrixPluginTests+Rollback.swift`: a
/// signed-out user never signed back in, the purge-after-a-carry caveat, and a client sign-out read as signed out.
extension RollbackMatrixPluginTests {

    // MARK: - Signing out

    /// A signed-out user is never signed back in, not even from the copy an earlier carry left
    ///
    /// - Given: The plugin build of the app saved alice under a user-pool-only configuration A; the app then added an
    ///   identity pool (configuration C) and rolled forward to the client, whose `.default` carried alice to C's key,
    ///   leaving A's copy, and signed her out (`{"noCredentials":{}}` under C)
    /// - When:
    ///    - Each plugin binary configures with C, and, over the same keychain again, with A (a rollback to the build
    ///      with the earlier configuration); then the client under A
    /// - Then:
    ///    - Under C each reads `.noCredentials`
    ///    - Under A each runs its own rule from C to A, which carries C's record over A's copy of alice: each reads
    ///      `.noCredentials`, and alice's copy is gone
    ///    - The client under A is signed out too
    ///
    func testMatrix_signedOutUserIsNeverSignedBackIn() async throws {
        let configurationA = AuthConfiguration(client: ClientOverKeychain.userPoolOnlyConfiguration)
        let accountA = AWSCognitoAuthCredentialStore.sessionAccount(for: configurationA)
        for binary in RollbackPluginBinary.allCases.map(Optional.some) + [nil] {
            let label = binary.map { "\($0)" } ?? "client"
            resetKeychain()
            let alice = try RollbackMatrixBytes.pluginPayload("userPoolOnly")
            try pluginStore(configurationA).saveCredential(decoded(alice))
            let clients = ClientOverKeychain(keychain: keychain)
            clients.script(userPool: ClientOverKeychain.userPool())
            var client: AmplifyCognitoClient? = try clients.client()
            let carried = await client?.currentSessionState()
            let signedOut = await client?.signOut()
            client = nil
            await clients.waitForBaseline()
            XCTAssertEqual(carried, .signedIn(AuthClientUser(username: "fixture-user", userId: "fixture-sub")), label)
            XCTAssertEqual(signedOut, .complete, label)
            XCTAssertEqual(try decoded(XCTUnwrap(keychain.value(service: pluginKeychainService, account: accountA))), try decoded(alice), label)

            guard let binary else {
                let underA = try clients.client(configuration: ClientOverKeychain.userPoolOnlyConfiguration)
                let state = await underA.currentSessionState()
                XCTAssertEqual(state, .signedOut, label)
                continue
            }
            XCTAssertEqual(try pluginStore(binary, clientPluginConfiguration).retrieveCredential(), .noCredentials, label)
            XCTAssertEqual(try pluginStore(binary, configurationA).retrieveCredential(), .noCredentials, label)
            XCTAssertEqual(try decoded(XCTUnwrap(keychain.value(service: pluginKeychainService, account: accountA))), .noCredentials, label)
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], label)
        }
    }

    /// Caveat: a purge after a carry leaves the earlier configuration's copy, which a rollback to that build reads.
    /// Pinned as it is, not changed; whether to change it is left open
    ///
    /// - Given: The plugin build of the app saved alice under a user-pool-only configuration A; under configuration C
    ///   (an identity pool added), alice was carried to C's key, leaving A's copy
    /// - When:
    ///    - The client's `.default` carries her and then purges `.default`; or, for contrast, the plugin build with C
    ///      carries her (its own rule) and signs out, which deletes its record
    ///    - Then each plugin binary configures with A
    /// - Then:
    ///    - Either way C's record is gone and A's copy of alice is untouched
    ///    - Under A each binary's rule from C to A finds nothing to carry, so each reads alice: the plugin's own
    ///      deleting sign-out leaves the same copy, so this is existing plugin behaviour, not one the client adds
    ///
    func testMatrix_purgeAfterACarry_leavesTheEarlierConfigurationsCopy_caveat() async throws {
        let configurationA = AuthConfiguration(client: ClientOverKeychain.userPoolOnlyConfiguration)
        let accountA = AWSCognitoAuthCredentialStore.sessionAccount(for: configurationA)
        let alice = try RollbackMatrixBytes.pluginPayload("userPoolOnly")
        for clientPurges in [true, false] {
            for binary in RollbackPluginBinary.allCases {
                let label = "\(clientPurges ? "client purge" : "plugin sign-out"), \(binary)"
                resetKeychain()
                try pluginStore(configurationA).saveCredential(decoded(alice))
                if clientPurges {
                    let clients = ClientOverKeychain(keychain: keychain)
                    clients.script(userPool: ClientOverKeychain.userPool())
                    var client: AmplifyCognitoClient? = try clients.client()
                    let carried = await client?.currentSessionState()
                    let purged = await client?.signOut(options: .init(purgeStoredSession: true))
                    client = nil
                    await clients.waitForBaseline()
                    XCTAssertEqual(carried, .signedIn(AuthClientUser(username: "fixture-user", userId: "fixture-sub")), label)
                    XCTAssertEqual(purged, .complete, label)
                } else {
                    let underC = pluginStore(binary, clientPluginConfiguration)
                    XCTAssertEqual(try underC.retrieveCredential(), try decoded(alice), label)
                    try underC.deleteCredential()
                }
                XCTAssertNil(keychain.value(service: pluginKeychainService, account: clientPluginAccount), label)
                XCTAssertEqual(try decoded(XCTUnwrap(keychain.value(service: pluginKeychainService, account: accountA))), try decoded(alice), label)

                XCTAssertEqual(try pluginStore(binary, configurationA).retrieveCredential(), try decoded(alice), label)
                XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], label)
            }
        }
    }

    /// A client sign-out is read by every plugin as signed out (G2 `session-noCredentials.json`)
    ///
    /// - Given: Alice signed in through the client with a label, then signed out through the client
    /// - When:
    ///    - Each plugin binary's credential store, configured as the same app, retrieves its credentials
    /// - Then:
    ///    - The client's bytes equal G2's `session-noCredentials.json` after decoding, and byte for byte
    ///    - Each reads `.noCredentials`, writing nothing and reading no client record
    ///
    func testMatrix_clientSignOut_readByEveryPluginAsSignedOut() async throws {
        let clients = ClientOverKeychain(keychain: keychain)
        clients.script(userPool: ClientOverKeychain.userPool(signingIn: "alice"))
        var client: AmplifyCognitoClient? = try clients.client()
        try await signInThroughTheClient(XCTUnwrap(client))
        try await client?.setSessionLabel("Work")
        let signedOut = await client?.signOut()
        client = nil
        await clients.waitForBaseline()
        XCTAssertEqual(signedOut, .complete)

        let stored = try XCTUnwrap(keychain.value(service: pluginKeychainService, account: clientPluginAccount))
        let golden = try RollbackMatrixBytes.goldenSession("session-noCredentials")
        XCTAssertEqual(try decoded(stored), try decoded(golden))
        XCTAssertEqual(stored, golden)

        for binary in RollbackPluginBinary.allCases {
            let store = pluginStore(binary, clientPluginConfiguration)
            keychain.resetMutations()
            XCTAssertEqual(try store.retrieveCredential(), .noCredentials, "\(binary)")
            XCTAssertEqual(keychain.mutations, [], "\(binary)")
            XCTAssertEqual(pluginKeychain.hiddenReadAccounts, [], "\(binary)")
        }
        XCTAssertEqual(keychain.value(service: pluginKeychainService, account: clientPluginAccount), stored)
    }
}
