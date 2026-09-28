//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    // MARK: Instance

    /// Sets the display text a picker shows for this session, or clears it with `nil`. The library cannot
    /// invent this. The label survives sign-out, and is cleared when a different user signs in to the
    /// session.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be written;
    ///   `AuthClientError.unknown` if the saved record is one this version cannot read; `CancellationError` if
    ///   the calling task is cancelled while it waits for the session's restore or record.
    func setSessionLabel(_ label: String?) async throws {
        let core = core
        try await core.setSessionLabel(label)
    }

    /// Completes the migration of an existing `AWSCognitoAuthPlugin` session into `.default`.
    ///
    /// Until its first write or this call, `.default` reads the plugin's saved session in place. Its first
    /// write lands on its own record, leaving the plugin's untouched, so rolling back to a plugin-only
    /// release still finds the user. This copies the plugin's record into `.default`'s own and then deletes
    /// the plugin's. Idempotent, and a no-op for every session other than `.default`.
    ///
    /// Running the plugin and this client side by side over the same session is not supported: see
    /// `SessionID.default`, including the warning logged when the two hold different users.
    ///
    /// **One refresh token.** After adoption `.default` and the plugin share one refresh token. Signing out
    /// through `Amplify.Auth` revokes it, and `.default` finds out at its next refresh.
    ///
    /// **Rollback.** Deleting the plugin's record is irreversible for plugin releases that predate its
    /// forward-compatible reader: rolled back to one of those, the app no longer finds its user. Releases
    /// with that reader fall back to `.default`'s record, so they still find the user.
    ///
    /// It deletes only what it adopted: a plugin record holding a different user, or rewritten while this
    /// call was copying it, is kept, and the call throws.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage failed; `AuthClientError.unknown` if a
    ///   record cannot be read, or the plugin's record holds a session that was not adopted. In each case
    ///   the plugin's record is kept. `CancellationError` if the calling task is cancelled while it waits for
    ///   the session's restore or record.
    func completeAdoption() async throws {
        let core = core
        try await core.completeAdoption()
    }

    // MARK: Saved sessions, without a client

    /// The sessions saved on this device under `configuration` and `accessGroup`, for an account picker.
    /// No network call.
    ///
    /// Only the sessions saved under this configuration's pools and this access group are listed: see
    /// "Changing the configuration" on `AmplifyCognitoClient`. After a pool configuration change, a session
    /// saved under the previous configuration that the client carries forward is listed once, as it will be
    /// restored. `.default` is listed from the plugin's record while it reads through to it.
    ///
    /// An interrupted sign-in is not a row: a session whose first sign-in stopped on a challenge is not listed
    /// until that sign-in completes, though a client built with its ID reports `.awaitingChallenge`. The listing
    /// also deletes interrupted sign-ins saved more than 15 minutes ago, which Cognito can no longer answer.
    ///
    /// `signOut` keeps a session's row, so a signed-out session is still resumable; pass
    /// `includingSignedOut: true` to list those rows too, with `kind == .signedOut`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration whose sessions to list; the same one the clients are built with.
    ///   - accessGroup: The keychain access group the sessions are stored in; the same value passed in
    ///     `Options.accessGroup`.
    ///   - includingSignedOut: Whether to list signed-out rows too. `false` by default.
    /// - Returns: One row per saved session, ordered by session ID. A record this version cannot read is left
    ///   out.
    /// - Throws: `AuthClientError.storageUnavailable` if the saved sessions could not be read. Never an
    ///   empty list for a failure.
    static func storedSessions(
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil,
        includingSignedOut: Bool = false
    ) async throws -> [StoredSession] {
        try await storedSessions(
            configuration: configuration,
            accessGroup: accessGroup,
            includingSignedOut: includingSignedOut,
            dependencies: .live
        )
    }

    /// Signs out a saved session the app is not holding: revokes its tokens, then clears them from this
    /// device, keeping its row. If a client for that session is live in this process, the sign-out goes
    /// through it, so its state, streams and providers see it at once.
    ///
    /// The revocation is never global, and touches no keychain beyond the session's record. A failed
    /// revocation is reported in `.partial`; the session is still cleared on this device.
    ///
    /// Never signs out a different user: if another process signed someone else in to this session ID
    /// meanwhile, they are left signed in and the result is `.superseded`.
    ///
    /// Outcomes are returned and failures are thrown: a thrown error means the session may still be
    /// signed in on this device.
    ///
    /// A session saved under a previous pool configuration that a restore would carry forward is carried
    /// first, then signed out, so it is revoked here and not restored signed in later. The copies of it this app
    /// left under earlier configurations are deleted while untouched since they were carried, if they provably hold the
    /// same user and are not a guest's; one holding a refresh token this sign-out did not revoke (rotated under
    /// its configuration), under this user pool, is revoked first. With each copy deleted, the interrupted sign-in
    /// saved under its configuration is deleted too (not revoked: a saved challenge holds no token). A session saved under a
    /// configuration this one does not carry from (another user pool, say) is not touched: sign it out with that
    /// configuration.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if storage could not be read or written, or
    ///   `storageUnavailable(.interrupted)` if the record kept changing under the sign-out (the first revoke
    ///   failure, if any, is its underlying error); `AuthClientError.sessionConfigurationMismatch` if a client
    ///   for this session is live in this process with a different user pool or identity pool, whose records
    ///   this call would change (sign it out through that client); `CancellationError` if the revoke was
    ///   cancelled, in which case nothing was cleared.
    static func signOutStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil
    ) async throws -> AuthClientSignOutResult {
        try await signOutStoredSession(
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: accessGroup,
            dependencies: .live
        )
    }

    /// **Local only**: deletes a saved session's records without contacting Cognito, so its refresh
    /// token stays valid server-side until it expires. Prefer `signOutStoredSession`, which revokes first.
    ///
    /// If a client for that session is live in this process, the purge goes through it: it moves to
    /// `.signedOut`, sends `.signedOut` if it held credentials, and its providers throw `notSignedIn`.
    /// For `.default`, the plugin's record is deleted too, so nothing resurrects the session. So are the copies
    /// of it this app left under earlier pool configurations (each only while untouched since it was carried, if it
    /// provably holds the same user and is not a guest's; their refresh tokens are not revoked), each with the
    /// interrupted sign-in saved under its configuration; and so is the session's record of which configuration
    /// it was kept under, so no later restore carries it forward. That record stays while it remembers other
    /// users' copies (alice's, when bob's session is purged), rewritten to name this configuration, where nothing
    /// is left, so it carries nothing. Purged with an older configuration than the one the session last ran with,
    /// the record under that later configuration is left, and is then a session of its own there.
    ///
    /// - Throws: `AuthClientError.storageUnavailable` if the session's configuration record, its record, or a
    ///   copy under an earlier configuration could not be read, a record could not be deleted, or the configuration
    ///   record could not be rewritten or deleted last, and `storageUnavailable(.interrupted)` if the session's
    ///   configuration record kept changing under the call;
    ///   `AuthClientError.sessionConfigurationMismatch` if a client for this session is live in this process with a
    ///   different user pool or identity pool (purge it through that client); `CancellationError` if the calling
    ///   task is cancelled while it waits for the session's record.
    static func purgeStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String? = nil
    ) async throws {
        try await purgeStoredSession(
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: accessGroup,
            dependencies: .live
        )
    }
}

// MARK: - Injectable implementations

extension AmplifyCognitoClient {

    static func storedSessions(
        configuration: AuthClientConfiguration,
        accessGroup: String?,
        includingSignedOut: Bool,
        dependencies: SessionCoreDependencies
    ) async throws -> [StoredSession] {
        // No gate: each record read is atomic, and every write commits before its operation returns.
        // Live sessions are not overlaid; the listing is what is saved.
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let io = SessionRecordIO(store: dependencies.makeStore(namespace), queue: SessionRecordIO.listingQueue)
        return try await io.storedSessions(includingSignedOut: includingSignedOut, sweepingChallengesAt: dependencies.now())
    }

    static func purgeStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String?,
        dependencies: SessionCoreDependencies
    ) async throws {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let gate = dependencies.gates.gate(for: namespace, sessionId: sessionId)
        let store = SessionRecordIO(store: dependencies.makeStore(namespace), queue: gate.ioQueue)
        // Whether a live session owns the record is decided under the gate. A session is registered
        // before it restores, and its restore takes this gate, so either it existed first and the purge
        // goes through it, or it was built meanwhile and its restore waits for the purge, then reads
        // nothing. Either way no live session keeps serving credentials from a deleted record.
        // The purge also deletes the session's copies under the namespaces its marker remembers, so it holds
        // their gates too, and refuses if the session is live under one of them.
        let live = try await withSessionGates(sessionId, namespace, dependencies) { () -> SessionCore? in
            if let live = liveSession(sessionId, in: namespace, dependencies: dependencies) {
                return live
            }
            try await store.purge(sessionId)
            dependencies.gates.memory(for: namespace, sessionId: sessionId).reset()
            return nil
        }
        if let live {
            try await live.purgeStoredRecord()
        }
    }

    static func signOutStoredSession(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        accessGroup: String?,
        dependencies: SessionCoreDependencies
    ) async throws -> AuthClientSignOutResult {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let gate = dependencies.gates.gate(for: namespace, sessionId: sessionId)
        let store = SessionRecordIO(store: dependencies.makeStore(namespace), queue: gate.ioQueue)
        let revoker = dependencies.makeRevoker(configuration)

        enum Routed: Sendable {
            case live(SessionCore)
            case done(AuthClientSignOutResult)
        }
        // Revoke first, then clear locally, holding the gate throughout — the same order as a live
        // session's sign-out. The plugin's stored format is read without an engine to tell who a
        // payload belongs to.
        // It may carry the session forward from, and sweeps, the namespaces its marker names: it holds their
        // gates too, and refuses if the session is live under one of them.
        let routed = try await withSessionGates(sessionId, namespace, dependencies) { () -> Routed in
            if let live = liveSession(sessionId, in: namespace, dependencies: dependencies) {
                return .live(live)
            }
            // A record a restore would carry forward from a previous configuration is carried now, so it is
            // signed out (and revoked) here, not restored signed in later.
            _ = try await store.perform { try $0.readCarryingForward(sessionId) }
            let outcome = try await SessionSignOut(
                sessionId: sessionId,
                store: store,
                describe: { payload in
                    let summary = PluginRecordSummary.peek(payload)
                    return summary.isRecognised
                        ? CredentialSummary(
                            kind: summary.kind,
                            username: summary.username,
                            userId: summary.userId,
                            identityId: summary.identityId
                        )
                        : nil
                },
                revoke: { payload, firstAttempt in
                    // No window here, so the hosted UI's sign-out never runs; when it would have, the cookie
                    // it leaves in the browser is reported.
                    var outcome = try await revoker.revoke(payload)
                    if firstAttempt, revoker.signOutPresentsBrowser(payload) {
                        outcome.hostedUIError = outcome.hostedUIError ?? SessionCore.noSignOutWindow()
                    }
                    return outcome
                },
                revokeCopy: { payload in
                    try await revoker.revoke(payload)
                }
            ).run()
            if outcome.endedSession {
                dependencies.gates.memory(for: namespace, sessionId: sessionId).reset()
            }
            return try .done(outcome.result())
        }
        switch routed {
        case .live(let core):
            return try await core.signOut()
        case .done(let result):
            return result
        }
    }

    /// Runs `body` holding the gate of `namespace` and those of every namespace the session's marker names (which
    /// a stored-session call may carry from or sweep), taken in one global order (`SessionRecordGates.holding`), so
    /// two calls over overlapping namespaces, or a call and a restore that carries, never deadlock.
    ///
    /// The marker is read, the gates taken, and the marker read again under them: if it now names a namespace
    /// whose gate is not held (a restore carried the session meanwhile), the gates are released and taken again,
    /// at most `SessionRecordGates.maximumGateAttempts` times.
    ///
    /// - Throws: `AuthClientError.sessionConfigurationMismatch` if the session is live in this process under any
    ///   other pool configuration in the same access group: its records are that session's to change, through a
    ///   client with its configuration. `storageUnavailable` if the marker could not be read, or kept changing.
    private static func withSessionGates<T: Sendable>(
        _ sessionId: SessionID,
        _ namespace: SessionStorageNamespace,
        _ dependencies: SessionCoreDependencies,
        _ body: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let reader = SessionRecordIO(store: dependencies.makeStore(namespace), queue: SessionRecordIO.listingQueue)
        @Sendable func named() async throws -> Set<SessionStorageNamespace> {
            let marker = try await reader.perform { try $0.marker(for: sessionId) }
            let components = (marker?.copies.map(\.poolNamespace) ?? []) + [marker?.poolNamespace].compactMap { $0 }
            return Set(components.compactMap(PoolNamespace.init(keyComponent:)).map {
                SessionStorageNamespace(pools: $0, accessGroup: namespace.accessGroup)
            }).union([namespace])
        }
        for _ in 1 ... SessionRecordGates.maximumGateAttempts {
            let held = try await named()
            let outcome: T? = try await dependencies.gates.holding(Array(held), sessionId: sessionId) {
                // Any other pool configuration in this access group: the one whose records a carry or sweep
                // touches. A live session in another access group has records of its own, untouched here.
                if let live = dependencies.registry.liveSession(for: sessionId),
                   live.namespace != namespace, live.namespace.accessGroup == namespace.accessGroup {
                    throw AuthClientError.sessionConfigurationMismatch(
                        sessionId,
                        "Session \"\(sessionId)\" is in use with a different user pool or identity pool, whose saved records this call would change.",
                        "Sign the session out, or purge it, through a client with that session's configuration."
                    )
                }
                guard try await named().isSubset(of: held) else {
                    return nil
                }
                return try await body()
            }
            if let outcome {
                return outcome
            }
        }
        throw AuthClientError.storageUnavailable(
            .interrupted,
            "Session \"\(sessionId)\"'s namespace marker kept changing.",
            "Retry the operation."
        )
    }

    /// The live session for `sessionId`, if it reads this namespace's record. A live session for the same
    /// ID on another namespace is a different record, behind a different gate, and is left alone.
    private static func liveSession(
        _ sessionId: SessionID,
        in namespace: SessionStorageNamespace,
        dependencies: SessionCoreDependencies
    ) -> SessionCore? {
        guard let live = dependencies.registry.liveSession(for: sessionId), live.namespace == namespace else {
            return nil
        }
        return live.session
    }
}
