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

/// The changes the plugin's rule deletes on, and the revoke of a deleted login of the same user pool.
extension DefaultSessionConfigurationChangeTests {

    // MARK: - The deleted changes

    /// - Given: the plugin under user pool A, holding alice, labelled through the client
    /// - When: a `.default` client restores under user pool B
    /// - Then:
    ///    - the old record is deleted with its sidecar, `.default` is signed out, and nothing is revoked: another
    ///      user pool's login stays valid until it expires
    ///    - back under A, no signed-out row is listed for a login alice never signed out of
    func testUserPoolChanged_deletesTheOldRecordAndDoesNotRevoke() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.both)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        let oldSidecar = SessionRecordKey.metaAccount(in: ChangeConfigs.both.poolNamespace)
        XCTAssertNotNil(harness.keychain.value(oldSidecar))
        cognito.clearCalls()

        var restoredClient: AmplifyCognitoClient? = makeClient(ChangeConfigs.otherUserPool)
        let restored = await restoredClient?.currentSessionState()
        restoredClient = nil
        await harness.waitForBaseline()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNil(harness.keychain.value(oldSidecar))
        let rowsBack = try await listed(ChangeConfigs.both, includingSignedOut: true)
        XCTAssertEqual(rowsBack, [])
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
        XCTAssertEqual(cognito.operations, [])
    }

    /// The old namespace's interrupted sign-in goes with its deleted record, as its sidecar does.
    ///
    /// - Given: the plugin under user pool A, holding alice, with an interrupted sign-in saved for `.default` under A
    /// - When: a `.default` client restores under user pool B; then the same again, with A's interrupted sign-in
    ///   undeletable
    /// - Then:
    ///    - A's record and A's interrupted sign-in are deleted
    ///    - with A's interrupted sign-in undeletable, the restore still deletes A's record and signs `.default` out
    func testUserPoolChanged_deletesTheOldInterruptedSignIn() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        let oldChallenge = SessionRecordKey.account(for: .default, in: ChangeConfigs.both.poolNamespace, kind: .challenge)
        harness.keychain.put(Data("an interrupted sign-in".utf8), oldChallenge)

        var restoredClient: AmplifyCognitoClient? = makeClient(ChangeConfigs.otherUserPool)
        let restored = await restoredClient?.currentSessionState()
        restoredClient = nil
        await harness.waitForBaseline()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertNil(harness.keychain.value(oldChallenge))

        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        harness.keychain.put(Data("an interrupted sign-in".utf8), oldChallenge)
        harness.keychain.failingRemovals(of: oldChallenge, with: errSecInteractionNotAllowed)

        let again = await makeClient(ChangeConfigs.otherUserPool).currentSessionState()

        XCTAssertEqual(again, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        harness.keychain.clearFailures()
    }

    /// The revoke uses the previous configuration's app client ID: `RevokeToken` refuses another client's token.
    ///
    /// - Given: the plugin under a user-pool-only configuration with app client 1, holding alice
    /// - When: a `.default` client restores under the same user pool with app client 2 and an identity pool added
    /// - Then:
    ///    - the old record is deleted, and `.default` is signed out
    ///    - one `RevokeToken` is sent, with alice's refresh token and app client 1; nothing is logged
    func testAppClientChangedWithAnIdentityPoolAdded_deletesAndRevokesWithTheOldClientID() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        cognito.clearCalls()
        cognito.once("RevokeToken") { (_: RevokeTokenInput) in RevokeTokenOutput() }

        let restored = await makeClient(ChangeConfigs.otherClientBoth).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        await waitUntil("the revoke is sent") { self.cognito.operations == ["RevokeToken"] }
        let revoke = try XCTUnwrap(cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first)
        XCTAssertEqual(revoke.clientId, "app-client-1")
        XCTAssertEqual(revoke.token, "refresh-alice-v1")
        XCTAssertEqual(revokers.configurations, [AuthConfiguration(client: ChangeConfigs.userPoolOnly)])
        try await settleRevokes()
        XCTAssertEqual(sink.lines(in: [ClientLog.category(ClientLog.defaultSession)]), [])
    }

    /// A deleted login is revoked even when recording the configuration then fails.
    ///
    /// - Given: the same change, with the write of `authConfiguration` failing with `errSecInteractionNotAllowed`
    /// - When: a `.default` client restores; then the keychain recovers and it restores again
    /// - Then:
    ///    - the first restore is `unavailable(.locked)`, the old record is deleted, and one `RevokeToken` is sent with
    ///      alice's refresh token and app client 1
    ///    - the second restore is `.signedOut` and records the new configuration; no second `RevokeToken` is sent
    func testAFailedConfigurationWriteAfterADelete_stillRevokesTheDeletedLogin() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        cognito.clearCalls()
        cognito.always("RevokeToken") { (_: RevokeTokenInput) in RevokeTokenOutput() }
        harness.keychain.failingSets(of: SessionRecordStore.pluginConfigurationAccount, with: errSecInteractionNotAllowed)
        let client = makeClient(ChangeConfigs.otherClientBoth)

        let locked = await client.currentSessionState()

        XCTAssertEqual(locked, .unavailable(.locked))
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        await waitUntil("the revoke is sent") { self.cognito.operations == ["RevokeToken"] }
        let revoke = try XCTUnwrap(cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first)
        XCTAssertEqual(revoke.clientId, "app-client-1")
        XCTAssertEqual(revoke.token, "refresh-alice-v1")
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.userPoolOnly))

        harness.keychain.clearFailures()
        let restored = await client.currentSessionState()
        try await settleRevokes()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.otherClientBoth))
        XCTAssertEqual(cognito.operations, ["RevokeToken"])
    }

    /// - Given: the same change, with `RevokeToken` failing
    /// - When: a `.default` client restores
    /// - Then:
    ///    - the old record is still deleted and `.default` signed out; the revoke is tried once, and one warning is
    ///      logged under `AmplifyCognitoClient.DefaultSession`, naming no one
    func testAFailedRevoke_logsOneWarningAndTheLoginStaysDeleted() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        cognito.clearCalls()
        cognito.always("RevokeToken") { (_: RevokeTokenInput) -> RevokeTokenOutput in
            throw AWSCognitoIdentityProvider.UnsupportedOperationException(message: "Revocation is not enabled for this app client")
        }

        let restored = await makeClient(ChangeConfigs.otherClientBoth).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.userPoolOnly)))
        let category = ClientLog.category(ClientLog.defaultSession)
        await waitUntil("the warning is logged") { !self.sink.lines(in: [category]).isEmpty }
        XCTAssertEqual(sink.lines(in: [category]), [
            "A login deleted by a configuration change could not be revoked; its refresh token stays valid until it expires."
        ])
        XCTAssertEqual(cognito.operations, ["RevokeToken"])
    }

    /// - Given: a guest under an identity-pool-only configuration
    /// - When: a `.default` client restores under another identity pool
    /// - Then:
    ///    - the guest's record is deleted, and nothing is revoked: it holds no user pool tokens
    func testDeletedGuest_isNotRevoked() async throws {
        try pluginSaves(ChangePayloads.guest(), under: ChangeConfigs.identityPoolOnly)

        let restored = await makeClient(ChangeConfigs.otherIdentityPoolOnly).currentSessionState()

        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.identityPoolOnly)))
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
    }
}
