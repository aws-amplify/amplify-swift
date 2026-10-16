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

/// Listing before a restore, and the static `signOutStoredSession` and `purgeStoredSession`.
extension DefaultSessionConfigurationChangeTests {

    // MARK: - Listing and the static calls

    /// - Given: alice's labelled record under a user-pool-only configuration, and no restore since an identity pool
    ///   was added
    /// - When: the saved sessions are listed under the new configuration
    /// - Then:
    ///    - `.default` is listed as it will be carried: alice, with her label; nothing is written
    func testListingBeforeRestore_afterACarryingChange_listsTheRow() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        var labelled: AmplifyCognitoClient? = makeClient(ChangeConfigs.userPoolOnly)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        harness.keychain.resetLogs()

        let rows = try await listed(ChangeConfigs.both)

        XCTAssertEqual(rows, [StoredSession(sessionId: .default, label: "Work", username: "alice", kind: .userPoolOnly)])
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: alice's record under user pool A, and no restore since the user pool changed
    /// - When: the saved sessions are listed under user pool B
    /// - Then:
    ///    - no `.default` row is listed, and nothing is written or deleted
    func testListingBeforeRestore_afterAClearingChange_listsNoRow() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.both)
        harness.keychain.resetLogs()

        let rows = try await listed(ChangeConfigs.otherUserPool, includingSignedOut: true)

        XCTAssertEqual(rows, [])
        XCTAssertFalse(harness.keychain.hasMutations)
    }

    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: `signOutStoredSession(.default)` runs under the new configuration
    /// - Then:
    ///    - the rule runs first: the record is carried, then revoked and signed out under the new account
    ///    - the old record is signed out too, as it still held the login just signed out;
    ///      `authConfiguration` still names the old configuration, which only a restore replaces
    func testStaticSignOutAfterAChange_appliesTheRuleFirst() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [old])
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.userPoolOnly))
    }

    /// A static sign-out that carried the app's login also signs out the
    /// record it carried from, so the signed-out user comes back under neither configuration.
    ///
    /// The app runs X (user pool only) and a static sign-out runs with Y (X with an identity pool added, a carrying
    /// change). Without signing out X's record, X would keep alice's revoked bytes: a restore under X would read them
    /// signed in, and a later move to Y would carry them over Y's signed-out record.
    ///
    /// - Given: alice's record under X, X recorded as the configuration the app last ran with, and alice's sidecar
    ///   with a label under X
    /// - When: `signOutStoredSession(.default)` runs under Y; then a `.default` client restores under X; then, released,
    ///   one restores under Y
    /// - Then:
    ///    - the result is `.complete`, with alice's tokens revoked once
    ///    - after it: Y's record and X's record both hold `{"noCredentials":{}}`; `authConfiguration` still names X;
    ///      X's sidecar holds the bytes it held before
    ///    - the restore under X is `.signedOut`, and lists alice's signed-out row with her label
    ///    - the restore under Y is `.signedOut` too: the carry from X brings the signed-out record
    func testStaticSignOutUnderACarryingConfiguration_signsOutTheRecordItCarriedFrom() async throws {
        let appConfiguration = ChangeConfigs.userPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        let before = try await pluginSignsIn("alice", under: appConfiguration)
        var labelled: AmplifyCognitoClient? = makeClient(appConfiguration)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        let appSidecar = SessionRecordKey.metaAccount(in: appConfiguration.poolNamespace)
        let sidecarBefore = try XCTUnwrap(harness.keychain.value(appSidecar))

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [before])
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))
        XCTAssertEqual(harness.keychain.value(appSidecar), sidecarBefore)

        var underApp: AmplifyCognitoClient? = makeClient(appConfiguration)
        let restoredUnderApp = await underApp?.currentSessionState()
        let rows = try await listed(appConfiguration, includingSignedOut: true)
        underApp = nil
        await harness.waitForBaseline()
        XCTAssertEqual(restoredUnderApp, .signedOut)
        XCTAssertEqual(rows.map(\.label), ["Work"])
        XCTAssertEqual(rows.map(\.username), ["alice"])

        let restoredUnderCarrying = await makeClient(carryingConfiguration).currentSessionState()
        XCTAssertEqual(restoredUnderCarrying, .signedOut)
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
    }

    /// The source is signed out even when the revoke fails: the user asked to sign out and is signed out
    /// on this device, so the record a carry came from must not bring them back. Only the server-side revoke failed.
    ///
    /// - Given: alice's record under X, the configuration the app last ran with, and `RevokeToken` failing
    /// - When: `signOutStoredSession(.default)` runs under Y (X with an identity pool added, a carrying change); then a
    ///   `.default` client restores under X; then, released, one restores under Y
    /// - Then:
    ///    - the result is `.partial(revokeTokenError:)` with the revoke's failure, and `signedOutLocally` is `true`
    ///    - X's record and Y's record both hold `{"noCredentials":{}}`, and `authConfiguration` still names X
    ///    - the restores under X and under Y are both `.signedOut`
    func testStaticSignOutUnderACarryingConfiguration_withAFailedRevoke_stillSignsOutTheSource() async throws {
        let appConfiguration = ChangeConfigs.userPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        let before = try await pluginSignsIn("alice", under: appConfiguration)
        let failure = AuthClientError.service(.network, "RevokeToken failed", "Retry later.")
        harness.revoker.scriptRevokeOutcome { _ in EngineSignOutOutcome(revokeError: failure) }

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .partialResult(revokeTokenError: failure))
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(harness.revoker.revokeCalls, [before])
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))

        var underApp: AmplifyCognitoClient? = makeClient(appConfiguration)
        let restoredUnderApp = await underApp?.currentSessionState()
        underApp = nil
        await harness.waitForBaseline()
        XCTAssertEqual(restoredUnderApp, .signedOut)

        let restoredUnderCarrying = await makeClient(carryingConfiguration).currentSessionState()
        XCTAssertEqual(restoredUnderCarrying, .signedOut)
    }

    /// The source is signed out only while it still holds the login just signed out.
    ///
    /// - Given: alice's record under X, and another writer saving bob under X while the static sign-out under Y revokes
    /// - When: `signOutStoredSession(.default)` runs under Y
    /// - Then:
    ///    - the result is `.complete` and Y's record is signed out; X's record holds bob, as the other writer saved it
    func testStaticSignOutUnderACarryingConfiguration_leavesASourceAnotherWriterChanged() async throws {
        let appConfiguration = ChangeConfigs.userPoolOnly
        try await pluginSignsIn("alice", under: appConfiguration)
        let bob = try await signedInPayload("bob", under: appConfiguration)
        let keychain = harness.keychain
        let source = account(appConfiguration)
        harness.revoker.scriptRevoke { _ in keychain.put(bob, source) }

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(source), bob)
    }

    /// A federated identity is signed out under the configuration it was carried from too: the user
    /// asked to sign out, so neither configuration may bring the identity back.
    ///
    /// - Given: a federated identity under X (identity pool only), the configuration the app last ran with
    /// - When: `signOutStoredSession(.default)` runs under Y (X with a user pool added, a carrying change); then a
    ///   `.default` client restores under X; then, released, one restores under Y
    /// - Then:
    ///    - the result is `.complete`; X's record and Y's record both hold `{"noCredentials":{}}`, and
    ///      `authConfiguration` still names X
    ///    - the restores under X and under Y are both `.signedOut`, and neither lists `.default`
    func testStaticSignOutUnderACarryingConfiguration_signsOutAFederatedSource() async throws {
        let appConfiguration = ChangeConfigs.identityPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        try pluginSaves(Self.federatedPayload(), under: appConfiguration)

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))

        var underApp: AmplifyCognitoClient? = makeClient(appConfiguration)
        let restoredUnderApp = await underApp?.currentSessionState()
        let rowsUnderApp = try await listed(appConfiguration)
        underApp = nil
        await harness.waitForBaseline()
        XCTAssertEqual(restoredUnderApp, .signedOut)
        XCTAssertEqual(rowsUnderApp, [])

        let restoredUnderCarrying = await makeClient(carryingConfiguration).currentSessionState()
        let rowsUnderCarrying = try await listed(carryingConfiguration)
        XCTAssertEqual(restoredUnderCarrying, .signedOut)
        XCTAssertEqual(rowsUnderCarrying, [])
    }

    /// A guest is left under the configuration it was carried from: it is nobody's login, and an app
    /// extension on that configuration may still use its identity, as for a named session's guest copy.
    ///
    /// - Given: a guest under X (identity pool only), the configuration the app last ran with
    /// - When: `signOutStoredSession(.default)` runs under Y (X with a user pool added, a carrying change); then a
    ///   `.default` client restores under X; then, released, one restores under Y
    /// - Then:
    ///    - the result is `.complete`; Y's record holds `{"noCredentials":{}}`, X's still holds the guest, and
    ///      `authConfiguration` still names X
    ///    - the restore under X is the same guest, and lists it
    ///    - the restore under Y carries it again from X: the same guest, listed
    func testStaticSignOutUnderACarryingConfiguration_leavesAGuestSource() async throws {
        let appConfiguration = ChangeConfigs.identityPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        let guest = try pluginSaves(ChangePayloads.guest(), under: appConfiguration)
        let guestRow = StoredSession(sessionId: .default, label: nil, username: nil, kind: .guest)

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), guest)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))

        var underApp: AmplifyCognitoClient? = makeClient(appConfiguration)
        let restoredUnderApp = await underApp?.currentSessionState()
        let rowsUnderApp = try await listed(appConfiguration)
        underApp = nil
        await harness.waitForBaseline()
        XCTAssertEqual(restoredUnderApp, .guest)
        XCTAssertEqual(rowsUnderApp, [guestRow])

        let restoredUnderCarrying = await makeClient(carryingConfiguration).currentSessionState()
        let rowsUnderCarrying = try await listed(carryingConfiguration)
        XCTAssertEqual(restoredUnderCarrying, .guest)
        XCTAssertEqual(rowsUnderCarrying, [guestRow])
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), guest)
    }

    /// A source that cannot be signed out logs one warning, naming no one; the session is still signed out here.
    ///
    /// - Given: alice's record under X, the configuration the app last ran with, and every write of X's record failing
    ///   with `errSecInteractionNotAllowed`
    /// - When: `signOutStoredSession(.default)` runs under Y (X with an identity pool added, a carrying change)
    /// - Then:
    ///    - the result is `.complete`, and Y's record holds `{"noCredentials":{}}`; X's still holds alice
    ///    - exactly `carrySourceSignOutFailedWarning` is logged under `AmplifyCognitoClient.DefaultSession`, without
    ///      alice's name
    func testStaticSignOutUnderACarryingConfiguration_whoseSourceCannotBeWritten_logsOneWarning() async throws {
        let appConfiguration = ChangeConfigs.userPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        let before = try await pluginSignsIn("alice", under: appConfiguration)
        harness.keychain.failingWrites(of: account(appConfiguration), with: errSecInteractionNotAllowed)
        let category = ClientLog.category(ClientLog.defaultSession)

        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(carryingConfiguration)), PluginRecordSummary.signedOutPayload)
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), before)
        await waitUntil("the warning is logged") { !self.sink.lines(in: [category]).isEmpty }
        XCTAssertEqual(sink.lines(in: [category]), [SessionCore.carrySourceSignOutFailedWarning])
        XCTAssertFalse(sink.lines(in: [category]).contains { $0.contains("alice") })
        harness.keychain.clearFailures()
    }

    /// A static call never clears the app's login: it may be made with a configuration other than the app's.
    ///
    /// - Given: alice's record under the app's configuration (user pool A), recorded as the plugin's last
    /// - When: `purgeStoredSession(.default)`, then `signOutStoredSession(.default)`, run under user pool B
    /// - Then:
    ///    - neither deletes or revokes alice's record, or changes `authConfiguration`; the next restore under B still
    ///      deletes it
    func testStaticCallsUnderAClearingChange_leaveTheAppsLoginAlone() async throws {
        let alice = try await pluginSignsIn("alice", under: ChangeConfigs.both)

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.otherUserPool,
            accessGroup: nil,
            dependencies: dependencies
        )
        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.otherUserPool,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.both)), alice)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.both))
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        try await settleRevokes()
        XCTAssertEqual(revokers.configurations, [])
        let restored = await makeClient(ChangeConfigs.otherUserPool).currentSessionState()
        XCTAssertEqual(restored, .signedOut)
        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
    }

    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: `purgeStoredSession(.default)` runs under the new configuration
    /// - Then:
    ///    - the rule carries first, so the purge deletes the carried record; the old record is kept, as the plugin keeps
    ///      it: a purge revokes nothing, so unlike a static sign-out it leaves the source valid; and
    ///      `authConfiguration` still names the old configuration, which only a restore replaces
    ///    - so the purge is undone under the new configuration, as the design's §6 states: listing under it still shows
    ///      alice's row, and a restore under it carries her back signed in
    func testStaticPurgeAfterACarryingChange_carriesFirst() async throws {
        let old = try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ChangeConfigs.both,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertNil(harness.keychain.value(account(ChangeConfigs.both)))
        XCTAssertEqual(harness.keychain.value(account(ChangeConfigs.userPoolOnly)), old)
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: ChangeConfigs.userPoolOnly))

        let rows = try await listed(ChangeConfigs.both)
        XCTAssertEqual(rows.map(\.sessionId), [.default])
        XCTAssertEqual(rows.first?.username, "alice")
        let restored = await makeClient(ChangeConfigs.both).currentSessionState()
        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertNotNil(harness.keychain.value(account(ChangeConfigs.both)))
    }

    /// A static carry never records the configuration: only the app running a
    /// configuration, a restore, records it. A purge only: it revokes nothing, so it leaves the record it carried from
    /// as it was; a static sign-out signs that record out too (the sign-out counterpart above).
    ///
    /// The app runs X (user pool only) and a static purge runs with Y (X with an identity pool added, a carrying
    /// change). Had the purge recorded Y, the app's next restore under X would see a change from Y to X, carry nothing
    /// back from Y (purged), and read X's record as the login's earlier copy. With nothing recorded, the plugin's rule
    /// sees X to X: nothing to carry or delete, as in the plugin, which runs its rule only when the app is configured.
    ///
    /// - Given: alice's record under X, X recorded as the configuration the app last ran with, and alice's sidecar
    ///   with a label under X
    /// - When: `purgeStoredSession(.default)` runs under Y; then a `.default` client restores under X
    /// - Then:
    ///    - after the purge: `authConfiguration` still names X; X's record and sidecar hold the bytes they held
    ///      before; Y's record and sidecar are gone (carried, then purged)
    ///    - the restore under X involves no carry back from Y, and writes nothing: `authConfiguration` still names X,
    ///      Y's account stays empty, and X's record and sidecar keep their bytes
    ///    - `.default` reads X's own record as it was before the purge: alice, signed in, with her label. It is the app's
    ///      login, which a static call made with another configuration never touches
    func testStaticPurgeUnderACarryingConfiguration_thenARestoreUnderTheAppsOwn_readsItsRecordAsItWas() async throws {
        let appConfiguration = ChangeConfigs.userPoolOnly
        let carryingConfiguration = ChangeConfigs.both
        let before = try await pluginSignsIn("alice", under: appConfiguration)
        var labelled: AmplifyCognitoClient? = makeClient(appConfiguration)
        try await labelled?.setSessionLabel("Work")
        labelled = nil
        await harness.waitForBaseline()
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))
        let appSidecar = SessionRecordKey.metaAccount(in: appConfiguration.poolNamespace)
        let carryingSidecar = SessionRecordKey.metaAccount(in: carryingConfiguration.poolNamespace)
        let sidecarBefore = try XCTUnwrap(harness.keychain.value(appSidecar))

        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: carryingConfiguration,
            accessGroup: nil,
            dependencies: dependencies
        )

        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), before)
        XCTAssertEqual(harness.keychain.value(appSidecar), sidecarBefore)
        XCTAssertNil(harness.keychain.value(account(carryingConfiguration)))
        XCTAssertNil(harness.keychain.value(carryingSidecar))
        harness.keychain.resetLogs()

        var restoredClient: AmplifyCognitoClient? = makeClient(appConfiguration)
        let restored = await restoredClient?.currentSessionState()
        let rows = try await listed(appConfiguration)
        restoredClient = nil
        await harness.waitForBaseline()

        XCTAssertEqual(harness.keychain.writtenAccounts, [])
        XCTAssertEqual(harness.keychain.removedAccounts, [])
        XCTAssertEqual(harness.keychain.recordedPluginConfiguration(), AuthConfiguration(client: appConfiguration))
        XCTAssertNil(harness.keychain.value(account(carryingConfiguration)))
        XCTAssertEqual(harness.keychain.value(account(appConfiguration)), before)
        XCTAssertEqual(harness.keychain.value(appSidecar), sidecarBefore)
        XCTAssertEqual(restored, .signedIn(alice))
        XCTAssertEqual(rows, [StoredSession(sessionId: .default, label: "Work", username: "alice", kind: .userPoolOnly)])
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// A hosted-UI sign-in that must return a user of no other session counts `.default`'s login as its restore will
    /// read it, before `.default` is restored (the plugin's rule would carry it).
    ///
    /// - Given: alice's record under a user-pool-only configuration, and no restore since an identity pool was added
    /// - When: a named session asks for its `.distinctFromOtherSessions` policy under the new configuration
    /// - Then:
    ///    - alice is excluded, held by `.default`; nothing is written
    func testDistinctFromOtherSessions_countsAPendingDefaultCarry() async throws {
        try await pluginSignsIn("alice", under: ChangeConfigs.userPoolOnly)
        harness.keychain.resetLogs()
        let work = makeClient(ChangeConfigs.both, ClientFixtures.id("work"))

        let (policy, holders) = try await work.core.identityPolicy(for: .distinctFromOtherSessions)

        XCTAssertEqual(policy, EngineIdentityPolicy(excludedSubjects: ["sub-alice"]))
        XCTAssertEqual(holders, ["sub-alice": .default])
        XCTAssertEqual(harness.keychain.writtenAccounts.filter { !$0.hasPrefix("amplify.1.") }, [])
    }
    #endif

    /// A federated identity's record, as the plugin stores one under an identity-pool-only configuration.
    static func federatedPayload() throws -> Data {
        try JSONEncoder().encode(AmplifyCredentials.identityPoolWithFederation(
            federatedToken: FederatedToken(token: "federated-token", provider: .facebook),
            identityID: "us-east-1:federated-identity",
            credentials: EngineAWSCredentials(
                accessKeyId: "AKID-federated",
                secretAccessKey: "secret-federated",
                sessionToken: "session-federated",
                expiration: Date(timeIntervalSince1970: 4_000_000_000)
            )
        ))
    }
}
