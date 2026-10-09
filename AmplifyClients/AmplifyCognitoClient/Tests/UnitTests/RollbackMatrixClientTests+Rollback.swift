//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAmplifyKeychain
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The rollback rows, the client's side: rotation, roll-forward, sign-out, mixed binaries, named
/// sessions and a newer sidecar, each across the `.released` and `.current` plugin binaries. Cognito's refresh-token
/// rotation is one `RotatingRefreshTokens` shared by the client and the plugin of a row.
extension RollbackMatrixClientTests {

    // MARK: - Refresh-token rotation

    /// Rotation rollback: the plugin is now signed in on the token the client rotated (the checklist's row 1).
    ///
    /// - Given: Refresh-token rotation on; alice signs in through the client on `.default`, and the client refreshes,
    ///   rotating her refresh token
    /// - When:
    ///    - The app rolls back to each plugin binary, whose store reads the keychain, and whose next refresh runs
    /// - Then:
    ///    - Each reads the rotated token; its refresh sends it and succeeds; no refresh is refused with
    ///      `RefreshTokenReuseException`, and no client record is read
    ///
    func testMatrix_rotationRollback_isNowSignedIn() async throws {
        for binary in RollbackPluginBinary.allCases {
            await relaunchWithAFreshKeychain()
            let cognito = RotatingRefreshTokens(live: "refresh-alice-v1")
            var client: AmplifyCognitoClient? = try makeClient()
            try await signInAlice(XCTUnwrap(client))
            scriptRotation(cognito, to: "rotated-by-the-client")
            live.scriptIdentityPool(version: 2)
            _ = try await client?.fetchAuthSession(options: .init(forceRefresh: true))
            client = nil
            await harness.waitForBaseline()

            let hiddenReads = HiddenReads()
            let read = try pluginStore(binary, recording: hiddenReads).retrieveCredential()
            XCTAssertEqual(read.signedInData?.cognitoUserPoolTokens.refreshToken, "rotated-by-the-client", "\(binary)")
            scriptRotation(cognito, to: "rotated-by-the-plugin")
            let refreshed = try await live.engine().refresh(JSONEncoder().encode(read), force: true)

            XCTAssertEqual(try AmplifyCredentials.decoded(refreshed).signedInData?.cognitoUserPoolTokens.refreshToken, "rotated-by-the-plugin", "\(binary)")
            XCTAssertEqual(cognito.sent, ["refresh-alice-v1", "rotated-by-the-client"], "\(binary)")
            XCTAssertEqual(cognito.refused, [], "\(binary)")
            XCTAssertEqual(hiddenReads.accounts, [], "\(binary)")
        }
    }

    /// Roll-forward after a plugin rotation: the client resumes on the newest token.
    ///
    /// - Given: Rotation on; alice signed in through the client; then each plugin binary in turn refreshes, rotating
    ///   her refresh token, and saves it, so the plugin rotated last
    /// - When:
    ///    - The app rolls forward to the client, which restores `.default` and refreshes
    /// - Then:
    ///    - It is signed in as alice and refreshes with the token the plugin rotated last; the refresh succeeds, so
    ///      no `sessionExpired`, and no refresh is ever refused
    ///
    func testMatrix_rollForwardAfterAPluginRotation_resumesOnTheNewestToken() async throws {
        let cognito = RotatingRefreshTokens(live: "refresh-alice-v1")
        var client: AmplifyCognitoClient? = try makeClient()
        try await signInAlice(XCTUnwrap(client))
        client = nil
        await harness.waitForBaseline()
        let hiddenReads = HiddenReads()
        live.scriptIdentityPool(version: 2)
        for binary in RollbackPluginBinary.allCases {
            let store = pluginStore(binary, recording: hiddenReads)
            let read = try store.retrieveCredential()
            scriptRotation(cognito, to: "rotated-by-the-\(binary)-plugin")
            let refreshed = try await live.engine().refresh(JSONEncoder().encode(read), force: true)
            try store.saveCredential(AmplifyCredentials.decoded(refreshed))
        }

        scriptRotation(cognito, to: "rotated-by-the-client")
        let rolledForward = try makeClient()
        let state = await rolledForward.currentSessionState()
        let session = try await rolledForward.fetchAuthSession(options: .init(forceRefresh: true))

        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(try session.userPoolTokensResult.get().refreshToken, "rotated-by-the-client")
        XCTAssertEqual(cognito.sent, ["refresh-alice-v1", "rotated-by-the-released-plugin", "rotated-by-the-current-plugin"])
        XCTAssertEqual(cognito.refused, [])
        XCTAssertEqual(hiddenReads.accounts, [])
    }

    // MARK: - Signing out

    /// A signed-out user is never signed back in, not even from the copy an earlier carry left.
    ///
    /// - Given: The plugin build of the app saved alice under a user-pool-only configuration A; the app added an
    ///   identity pool (configuration C) and rolled forward to the client, whose `.default` carried alice to C's key,
    ///   leaving A's copy, and signed her out
    /// - When:
    ///    - Each plugin binary configures with C, and, over the same keychain again, with A; then the client under A
    /// - Then:
    ///    - Under C each reads `.noCredentials`; under A each runs its own rule from C to A, which carries C's record
    ///      over A's copy of alice, and reads `.noCredentials`
    ///    - The client under A is signed out too
    ///
    func testMatrix_signedOutUserIsNeverSignedBackIn() async throws {
        let configurationA = ChangeConfigs.userPoolOnly
        let accountA = SessionRecordKey.pluginSessionAccount(in: configurationA.poolNamespace)
        for binary in RollbackPluginBinary.allCases.map(Optional.some) + [nil] {
            let label = binary.map { "\($0)" } ?? "client"
            await relaunchWithAFreshKeychain()
            let both = try await live.signedInPayload("alice", on: live.engine())
            let alice = try XCTUnwrap(CredentialSlot.userPoolTokensOnly(both))
            try pluginStore(configurationA).saveCredential(AmplifyCredentials.decoded(alice))
            var client: AmplifyCognitoClient? = try makeClient()
            let carried = await client?.currentSessionState()
            live.scriptSignOut()
            let signedOut = await client?.signOut()
            client = nil
            await harness.waitForBaseline()
            XCTAssertEqual(carried, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")), label)
            XCTAssertEqual(signedOut, .complete, label)
            XCTAssertEqual(try AmplifyCredentials.decoded(XCTUnwrap(harness.keychain.value(accountA))), try AmplifyCredentials.decoded(alice), label)

            guard let binary else {
                let state = await (try makeClient(configuration: configurationA)).currentSessionState()
                XCTAssertEqual(state, .signedOut, label)
                continue
            }
            let hiddenReads = HiddenReads()
            XCTAssertEqual(try pluginStore(binary, recording: hiddenReads).retrieveCredential(), .noCredentials, label)
            XCTAssertEqual(try pluginStore(binary, configurationA, recording: hiddenReads).retrieveCredential(), .noCredentials, label)
            XCTAssertEqual(try AmplifyCredentials.decoded(XCTUnwrap(harness.keychain.value(accountA))), .noCredentials, label)
            XCTAssertEqual(hiddenReads.accounts, [], label)
        }
    }

    /// Caveat: a purge after a carry leaves the earlier configuration's copy, which a rollback to that build reads.
    /// Pinned as it is, not changed; whether to change it is left open.
    ///
    /// - Given: The plugin build of the app saved alice under a user-pool-only configuration A; under configuration C
    ///   (an identity pool added), alice was carried to C's key, leaving A's copy
    /// - When:
    ///    - The client's `.default` carries her and then purges `.default`; or, for contrast, the plugin build with C
    ///      carries her (its own rule) and signs out, which deletes its record
    ///    - Then each plugin binary configures with A; and, after the purge, the client under A
    /// - Then:
    ///    - Either way C's record is gone and A's copy of alice is untouched
    ///    - Under A each binary's rule from C to A finds nothing to carry, so each reads alice, and the client under A
    ///      restores her: the plugin's own deleting sign-out leaves the same copy, so this is existing plugin behaviour
    ///
    func testMatrix_purgeAfterACarry_leavesTheEarlierConfigurationsCopy_caveat() async throws {
        let configurationA = ChangeConfigs.userPoolOnly
        let accountA = SessionRecordKey.pluginSessionAccount(in: configurationA.poolNamespace)
        for clientPurges in [true, false] {
            for binary in RollbackPluginBinary.allCases.map(Optional.some) + [nil] {
                guard clientPurges || binary != nil else {
                    continue
                }
                let label = "\(clientPurges ? "client purge" : "plugin sign-out"), \(binary.map { "\($0)" } ?? "client")"
                await relaunchWithAFreshKeychain()
                let both = try await live.signedInPayload("alice", on: live.engine())
                let alice = try XCTUnwrap(CredentialSlot.userPoolTokensOnly(both))
                try pluginStore(configurationA).saveCredential(AmplifyCredentials.decoded(alice))
                let hiddenReads = HiddenReads()
                if clientPurges {
                    var client: AmplifyCognitoClient? = try makeClient()
                    let carried = await client?.currentSessionState()
                    live.scriptSignOut()
                    let purged = await client?.signOut(options: .init(purgeStoredSession: true))
                    client = nil
                    await harness.waitForBaseline()
                    XCTAssertEqual(carried, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")), label)
                    XCTAssertEqual(purged, .complete, label)
                } else if let binary {
                    let underC = pluginStore(binary, recording: hiddenReads)
                    XCTAssertEqual(try underC.retrieveCredential(), try AmplifyCredentials.decoded(alice), label)
                    try underC.deleteCredential()
                }
                XCTAssertNil(harness.keychain.value(pluginAccount), label)
                XCTAssertEqual(try AmplifyCredentials.decoded(XCTUnwrap(harness.keychain.value(accountA))), try AmplifyCredentials.decoded(alice), label)

                guard let binary else {
                    let state = await (try makeClient(configuration: configurationA)).currentSessionState()
                    XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")), label)
                    continue
                }
                XCTAssertEqual(try pluginStore(binary, configurationA, recording: hiddenReads).retrieveCredential(), try AmplifyCredentials.decoded(alice), label)
                XCTAssertEqual(hiddenReads.accounts, [], label)
            }
        }
    }

    // MARK: - Mixed binaries

    /// Mixed binaries at rest: an extension on a plugin binary, the app on the client.
    ///
    /// - Given: One keychain under an app that runs the client's `.default` and an extension that runs a plugin binary
    /// - When:
    ///    - The app signs alice in and quits; the extension reads, refreshes (rotating her token) and saves; the app
    ///      relaunches and refreshes, then signs out; the extension reads again
    /// - Then:
    ///    - Each launch sees the other side's latest login: the extension reads the app's alice; the app restores
    ///      alice and its refresh sends the extension's rotated token, which Cognito accepts; the extension then reads
    ///      the app's sign-out
    ///
    func testMatrix_mixedBinaries_extensionOnThePluginAppOnTheClient_atRest() async throws {
        for binary in RollbackPluginBinary.allCases {
            await relaunchWithAFreshKeychain()
            let cognito = RotatingRefreshTokens(live: "refresh-alice-v1")
            var app: AmplifyCognitoClient? = try makeClient()
            try await signInAlice(XCTUnwrap(app))
            app = nil
            await harness.waitForBaseline()
            let appLogin = try XCTUnwrap(harness.keychain.value(pluginAccount))

            let hiddenReads = HiddenReads()
            let extensionStore = pluginStore(binary, recording: hiddenReads)
            let read = try extensionStore.retrieveCredential()
            XCTAssertEqual(read, try AmplifyCredentials.decoded(appLogin), "\(binary)")
            scriptRotation(cognito, to: "rotated-by-the-extension")
            live.scriptIdentityPool(version: 2)
            try await extensionStore.saveCredential(AmplifyCredentials.decoded(live.engine().refresh(JSONEncoder().encode(read), force: true)))

            scriptRotation(cognito, to: "rotated-by-the-app")
            app = try makeClient()
            let relaunched = await app?.currentSessionState()
            let session = try await app?.fetchAuthSession(options: .init(forceRefresh: true))
            live.scriptSignOut()
            let signedOut = await app?.signOut()
            app = nil
            await harness.waitForBaseline()

            XCTAssertEqual(relaunched, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")), "\(binary)")
            XCTAssertEqual(try session?.userPoolTokensResult.get().refreshToken, "rotated-by-the-app", "\(binary)")
            XCTAssertEqual(cognito.sent, ["refresh-alice-v1", "rotated-by-the-extension"], "\(binary)")
            XCTAssertEqual(cognito.refused, [], "\(binary)")
            XCTAssertEqual(signedOut, .complete, "\(binary)")
            XCTAssertEqual(try pluginStore(binary, recording: hiddenReads).retrieveCredential(), .noCredentials, "\(binary)")
            XCTAssertEqual(hiddenReads.accounts, [], "\(binary)")
        }
    }

    // MARK: - Named sessions

    /// Named sessions disappear on a rollback to a plugin-only release and return on roll-forward, unless a
    /// released plugin's access-group transition wipes them.
    ///
    /// - Given: Two named sessions, work and home, signed in through the client, and no `.default` login
    /// - When:
    ///    - The app rolls back to each plugin binary, which retrieves, signs bob in and out; then rolls forward
    ///    - Then each binary's access-group transition without migration runs: the released one's service-wide
    ///      `_removeAll()`, emulated by `removeAll()` on its view, and the current one's own
    /// - Then:
    ///    - Each binary is signed out, reads no client record, and leaves the named records' bytes unchanged
    ///    - Rolled forward, work and home are listed and signed in again
    ///    - After the transition, the current plugin's scoped wipe has kept them, and the released one has deleted
    ///      them: neither is listed, and work restores signed out (a documented caveat)
    ///
    func testMatrix_namedSessionsDisappearOnRollbackAndReturnOnRollForward() async throws {
        let work = ClientFixtures.id("work")
        let home = ClientFixtures.id("home")
        let namedAccounts = [work, home].map { SessionRecordKey.account(for: $0, in: StorageFixtures.pools, kind: .session) }
        for binary in RollbackPluginBinary.allCases {
            await relaunchWithAFreshKeychain()
            for sessionId in [work, home] {
                try await signInAlice(makeClient(sessionId))
            }
            await harness.waitForBaseline()
            let namedBytes = namedAccounts.map { harness.keychain.value($0) }
            let hiddenReads = HiddenReads()
            let pluginKeychain = harness.keychain.itemStore(service: SessionRecordStore.unsharedService)

            let store = pluginStore(binary, recording: hiddenReads)
            XCTAssertThrowsError(try store.retrieveCredential(), "\(binary)") { error in
                XCTAssertEqual(error as? EngineCredentialStoreError, .itemNotFound)
            }
            try await store.saveCredential(AmplifyCredentials.decoded(live.signedInPayload("bob", on: live.engine())))
            try store.deleteCredential()
            XCTAssertEqual(hiddenReads.accounts, [], "\(binary)")
            XCTAssertEqual(namedAccounts.map { harness.keychain.value($0) }, namedBytes, "\(binary)")

            let rolledForward = try await listed()
            XCTAssertEqual(Set(rolledForward.map(\.sessionId)), [work, home], "\(binary)")
            let workBack = await (try makeClient(work)).currentSessionState()
            XCTAssertEqual(workBack, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")), "\(binary)")
            await harness.waitForBaseline()

            try accessGroupTransitionWithoutMigration(binary, over: pluginKeychain, recording: hiddenReads)
            let afterTransition = try await listed(includingSignedOut: true)
            switch binary {
            case .released:
                XCTAssertEqual(afterTransition, [], "\(binary)")
                let workAfter = await (try makeClient(work)).currentSessionState()
                XCTAssertEqual(workAfter, .signedOut, "\(binary)")
            case .current:
                XCTAssertEqual(Set(afterTransition.map(\.sessionId)), [work, home], "\(binary)")
            }
        }
    }

    // MARK: - A newer schema

    /// A newer schema's `.default` sidecar is shown as absent and never overwritten (replaces matrix 03 row 10).
    ///
    /// - Given: The plugin's record for alice, and beside it a schema-2 `$default.meta` holding a label
    /// - When:
    ///    - The client lists and restores `.default`, tries to label it, refreshes and signs out; then each plugin
    ///      binary retrieves, saves and deletes its record
    /// - Then:
    ///    - The row and the session show no label, labelling fails, and the refresh and sign-out succeed
    ///    - The sidecar is never written or deleted, and no plugin reads a client record
    ///
    func testMatrix_newerSchemaSidecar_isLeftAlone() async throws {
        let alice = try await live.signedInPayload("alice", on: live.engine())
        try pluginStore().saveCredential(AmplifyCredentials.decoded(alice))
        let newerSidecar = Data(#"{"label":"Future","lastWriteTimestamp":1,"schemaVersion":2,"userId":"sub-alice","username":"alice"}"#.utf8)
        harness.keychain.put(newerSidecar, sidecarAccount)

        let rows = try await listed()
        var client: AmplifyCognitoClient? = try makeClient()
        let state = await client?.currentSessionState()
        do {
            try await client?.setSessionLabel("Mine")
            XCTFail("A newer sidecar must not be labelled over")
        } catch {}
        live.scriptRefresh("alice", version: 2)
        live.scriptIdentityPool(version: 2)
        _ = try await client?.fetchAuthSession(options: .init(forceRefresh: true))
        live.scriptSignOut()
        let signedOut = await client?.signOut()
        client = nil
        await harness.waitForBaseline()

        XCTAssertEqual(rows, [StoredSession(sessionId: .default, label: nil, username: "alice", kind: .userPoolAndIdentityPool)])
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(signedOut, .complete)
        XCTAssertEqual(harness.keychain.value(pluginAccount), try JSONEncoder().encode(AmplifyCredentials.noCredentials))
        let hiddenReads = HiddenReads()
        for binary in RollbackPluginBinary.allCases {
            let store = pluginStore(binary, recording: hiddenReads)
            XCTAssertEqual(try store.retrieveCredential(), .noCredentials, "\(binary)")
            try store.saveCredential(AmplifyCredentials.decoded(alice))
            try store.deleteCredential()
            // The next binary starts from the client's sign-out again.
            try store.saveCredential(.noCredentials)
        }
        XCTAssertFalse(harness.keychain.writtenAccounts.contains(sidecarAccount))
        XCTAssertFalse(harness.keychain.removedAccounts.contains(sidecarAccount))
        XCTAssertEqual(harness.keychain.value(sidecarAccount), newerSidecar)
        XCTAssertEqual(hiddenReads.accounts, [])
    }

    // MARK: - Helpers

    /// A new keychain and Cognito, after the last row's clients are gone: the next binary starts from nothing.
    func relaunchWithAFreshKeychain() async {
        await harness.waitForBaseline()
        harness = ClientHarness()
        live = LiveEngineHarness()
    }

    /// Answers every refresh from `cognito`, rotating its live token to `next`.
    func scriptRotation(_ cognito: RotatingRefreshTokens, to next: String) {
        live.cognito.always("GetTokensFromRefreshToken") { (input: GetTokensFromRefreshTokenInput) in
            try cognito.refresh(input, rotatingTo: next)
        }
    }

    /// `binary`'s access-group transition without migration, from no access group to one, over the unshared service:
    /// for `.released`, the service-wide `_removeAll()` that 2.62.0 still calls, emulated on its view; for `.current`,
    /// the plugin's own transition, through its credential store's keychain seam.
    func accessGroupTransitionWithoutMigration(
        _ binary: RollbackPluginBinary,
        over pluginKeychain: any KeychainItemStoreBehavior,
        recording hiddenReads: HiddenReads
    ) throws {
        switch binary {
        case .released:
            try binary.keychainStore(over: pluginKeychain, recording: hiddenReads).removeAll()
        case .current:
            let suite = "RollbackMatrixClientTests.\(UUID().uuidString)"
            let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { userDefaults.removePersistentDomain(forName: suite) }
            let keychain = harness.keychain
            _ = AWSCognitoAuthCredentialStore(
                authConfiguration: AuthConfiguration(client: ClientFixtures.configuration),
                accessGroup: "group.acme",
                migrateKeychainItemsOfUserSession: false,
                userDefaults: userDefaults,
                makeKeychainStore: { service, accessGroup -> any KeychainItemStoreBehavior in
                    accessGroup == nil ? pluginKeychain : keychain.itemStore(service: service, accessGroup: accessGroup)
                },
                logger: DiscardingEngineLogger()
            )
        }
    }
}
