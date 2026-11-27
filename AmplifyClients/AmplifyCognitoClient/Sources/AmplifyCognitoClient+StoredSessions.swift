//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    // MARK: Instance

    /// Sets the display text a picker shows for this session, or clears it with `nil`. The library cannot
    /// invent this. The label survives sign-out, and is cleared when a different user signs in to the
    /// session through a client; for `.default`, a different user's sign-in through the Auth plugin only
    /// hides it (see `AmplifyCognitoClientStoredSession.label`).
    ///
    /// It replaces whatever label the session's ID was created with (`AmplifyCognitoClientSessionID.label`), which a sign-in saves only
    /// when the session's row keeps none.
    ///
    /// - Throws: `AmplifyCognitoClientError.storageUnavailable` if storage could not be written;
    ///   `AmplifyCognitoClientError.unknown` if the saved record is one this version cannot read; `CancellationError` if
    ///   the calling task is cancelled while it waits for the session's restore or record.
    func setSessionLabel(_ label: String?) async throws {
        let core = core
        try await core.setSessionLabel(label)
    }

    // MARK: Saved sessions, without a client

    /// The sessions saved on this device under `configuration` and `accessGroup`, for an account picker.
    /// No network call.
    ///
    /// Only the sessions saved under this configuration's pools and this access group are listed: see
    /// "Changing the configuration" on `AmplifyCognitoClient`. After a pool configuration change, a session
    /// saved under the previous configuration that the client carries forward is listed once, as it will be
    /// restored. `.default` is listed from the plugin's saved login, which it uses, with its label, as the plugin's
    /// configuration-change rule will leave it at its next restore: a login that rule carries here is listed, and one
    /// it deletes is not.
    ///
    /// Each row's `state` is the state a client built with its `sessionId` would restore to, read from what is
    /// saved (`AmplifyCognitoClientStoredSession.state`). A sign-in that stopped on a challenge is listed as `.awaitingChallenge(step)`,
    /// also when nothing else is saved for the session (a first sign-in interrupted at MFA): build a client with the
    /// row's ID and answer the step its `currentSessionState()` reports with `confirmSignIn`. A saved record this
    /// version cannot read is a `.failed` row. The listing is what is saved: a client live in this process is not
    /// consulted. It also deletes interrupted sign-ins saved more than 15 minutes ago, which Cognito can no longer
    /// answer, and lists none of them.
    ///
    /// `signOut` keeps a session's row, so a signed-out session is still resumable; pass
    /// `includingSignedOut: true` to list those rows too, with `state == .signedOut`. A signed-out row whose
    /// sign-in is waiting on a challenge is `.awaitingChallenge`, and is listed either way.
    ///
    /// - Parameters:
    ///   - configuration: The configuration whose sessions to list; the same one the clients are built with.
    ///   - accessGroup: The keychain access group the sessions are stored in; the same value passed in
    ///     `Options.accessGroup`.
    ///   - includingSignedOut: Whether to list `.signedOut` rows too. `false` by default.
    /// - Returns: One row per saved session, ordered by session ID. A record this version cannot read is a row
    ///   whose `state` is `.failed`.
    /// - Throws: `AmplifyCognitoClientError.storageUnavailable` if the saved sessions could not be read, a saved interrupted
    ///   sign-in the listing has to read among them (one beside a signed-out or guest row, or with nothing else
    ///   saved). Never an empty list for a failure.
    static func storedSessions(
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String? = nil,
        includingSignedOut: Bool = false
    ) async throws -> [AmplifyCognitoClientStoredSession] {
        try await storedSessions(
            configuration: configuration,
            accessGroup: accessGroup,
            includingSignedOut: includingSignedOut,
            dependencies: .live
        )
    }

    /// Signs out a saved session the app is not holding: revokes its tokens, then clears them from this
    /// device, keeping its row unless `options.purgeStoredSession` removes it. If a client for that session is
    /// live in this process, the sign-out goes through it with the same options, so its state, streams and
    /// providers see it at once.
    ///
    /// The revocation is global only with `options.globalSignOut`, as `signOut(options:)`'s is; it sends the saved
    /// access token as it is, so for a session whose access token has expired Cognito refuses it, and the refresh
    /// token is then not revoked either (`.partial` with a `globalSignOutError`). With
    /// `options.purgeStoredSession`, the row is removed once the session is signed out, as `purgeStoredSession`
    /// removes it; if only that fails, the result is `.partial` with a `storageError`, and the row is kept, signed
    /// out. For `.default`, when the Auth plugin's configuration-change rule carried the login here for this call,
    /// the purge removes this configuration's record only: the login it was carried from is left signed out, with its
    /// label, and its signed-out row is listed, and carried here again, until `.default` first restores under this
    /// configuration. It changes no other session's records and no device records; for `.default`,
    /// which is the Auth plugin's saved login, it also clears the AWSMobileClient logins the plugin would otherwise
    /// migrate back into it, as the plugin's own sign-out does. A failed revocation is reported in `.partial`; the
    /// session is still cleared on this device. With no client for the session live in this process, the revoke goes
    /// through SDK clients built from `configuration` alone, so a `configureUserPoolClient` the app passes to its clients
    /// (a custom endpoint, a proxy, certificate pinning) is not applied: hold a client for the session to sign out
    /// through it instead.
    ///
    /// Never signs out a user who signs in while the call runs: if another process signs someone else in to
    /// this session ID meanwhile, they are left signed in and the result is `.failed(.invalidState)`. The call
    /// takes no expected user, so it signs out whoever the saved session holds when it starts.
    ///
    /// Never throws, as `signOut(options:)` does not: `.failed` means the session is still signed in on this
    /// device; `.complete` and `.partial` that it is signed out here.
    ///
    /// A session saved under a previous pool configuration that a restore would carry forward is carried
    /// first, then signed out, so it is revoked here and not restored signed in later. The copies of it this app
    /// left under earlier configurations are deleted while untouched since they were carried, if they provably hold the
    /// same user and are not a guest's; one holding a refresh token this sign-out did not revoke (rotated under
    /// its configuration), under this user pool, is revoked first. With each copy deleted, the interrupted sign-in
    /// saved under its configuration is deleted too (not revoked: a saved challenge holds no token). A session saved under a
    /// configuration this one does not carry from (another user pool, say) is not touched: sign it out with that
    /// configuration. For `.default`, a login the Auth plugin's configuration-change rule carries here is carried first,
    /// then signed out; a change the rule would delete on is left alone, the app's login included, so a call with a
    /// configuration other than the app's never deletes the app's login. The configuration the app last ran with stays
    /// recorded (only a restore records one). After a carry, the login it came from is signed out too while it still
    /// holds the user (or federated identity) just signed out, so the user stays signed out under both configurations.
    /// A guest's is left, as a named session leaves a guest's copy: a restore under either configuration then finds
    /// the same guest.
    ///
    /// - Returns: `.complete`, or `.partial` with the revoke's or the global sign-out's failure, the hosted UI's
    ///   cookie left behind, or the purge's failure (`storageError`), when the session is signed out on this device. `.failed`, and the session is still signed in:
    ///   `storageUnavailable` if storage could not be read or written, or `storageUnavailable(.interrupted)` if
    ///   the record kept changing under the sign-out (the revoke's failure, if any, is its underlying error, mapped as
    ///   any other call maps it; when the revoke succeeded, a session whose sign-in shared the browser's cookies has
    ///   the no-window hosted-UI error underneath, whose text says the session was signed out on this device, though
    ///   it is not); `sessionConfigurationMismatch` if a client for this session is live in this process
    ///   with a different user pool or identity pool, whose records this call would change (sign it out through that
    ///   client); `invalidState` if a different user signed in meanwhile; `unknown` with an underlying
    ///   `CancellationError` if the calling task was cancelled before anything was revoked.
    @discardableResult
    static func signOutStoredSession(
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String? = nil,
        options: AmplifyCognitoClientSignOutOptions = AmplifyCognitoClientSignOutOptions()
    ) async -> AmplifyCognitoClientSignOutResult {
        await signOutStoredSession(
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: accessGroup,
            options: options,
            dependencies: .live
        )
    }

    /// **Local only**: deletes a saved session's records without contacting Cognito, so its refresh
    /// token stays valid server-side until it expires. Prefer `signOutStoredSession`, which revokes first.
    ///
    /// If a client for that session is live in this process, the purge goes through it: it moves to
    /// `.signedOut`, sends `.signedOut` if it held credentials, and its providers throw `notSignedIn`.
    /// For `.default`, this configuration's copy of the plugin's saved login is deleted. A login the Auth plugin's
    /// configuration-change rule carries here is carried first, and a change it would delete on is left alone, the
    /// previous configuration's login included, and so is the login a carry came from (a purge revokes nothing), which
    /// the next restore under the new configuration carries here again: use `signOutStoredSession` to end the session
    /// under both configurations. The AWSMobileClient logins the plugin would migrate back into it are cleared too, as
    /// a sign-out clears them. For a named session, the copies of it this app left under earlier pool configurations
    /// are deleted too (each only while untouched since it was carried, if it provably holds the same user and is not a
    /// guest's; their refresh tokens are not revoked), each with the interrupted sign-in saved under its configuration;
    /// and so is the session's record of which configuration it was kept under, so no later restore carries it forward. That record stays while it remembers other
    /// users' copies (alice's, when bob's session is purged), rewritten to name this configuration, where nothing
    /// is left, so it carries nothing. Purged with an older configuration than the one the session last ran with,
    /// the record under that later configuration is left, and is then a session of its own there.
    ///
    /// - Throws: `AmplifyCognitoClientError.storageUnavailable` if the session's configuration record, its record, or a
    ///   copy under an earlier configuration could not be read, a record could not be deleted, or the configuration
    ///   record could not be rewritten or deleted last, and `storageUnavailable(.interrupted)` if the session's
    ///   configuration record kept changing under the call;
    ///   `AmplifyCognitoClientError.sessionConfigurationMismatch` if a client for this session is live in this process with a
    ///   different user pool or identity pool (purge it through that client); `CancellationError` if the calling
    ///   task is cancelled while it waits for the session's record.
    static func purgeStoredSession(
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String? = nil
    ) async throws {
        try await purgeStoredSession(
            sessionId: sessionId,
            configuration: configuration,
            accessGroup: accessGroup,
            dependencies: .live
        )
    }

    /// Sets the display text a picker shows for a saved session, or clears it with `nil`, without building a
    /// client for it. The label follows the rules of the instance `setSessionLabel(_:)`: it survives sign-out, and
    /// is cleared when a different user signs in (see `AmplifyCognitoClientStoredSession.label`). A label `sessionId` was created with
    /// (`AmplifyCognitoClientSessionID.label`) is ignored here: only a client's sign-in saves it.
    ///
    /// If a client for that session is live in this process, the label is set through it, as its own
    /// `setSessionLabel(_:)` sets it (after its restore), so the client and the listing agree at once. Otherwise
    /// the saved row is written with no network call. A session with nothing saved gets a labelled signed-out row,
    /// listed with `includingSignedOut: true`; clearing the label of a session with nothing saved writes nothing.
    /// The record is first read as a restore under this configuration reads it, as `signOutStoredSession` reads it:
    /// a session saved under a previous pool configuration that a restore would carry forward is carried, so the
    /// label lands on the record the next restore finds; for `.default`, that is the Auth plugin's
    /// configuration-change rule, applied only when it carries, and the login it carried from is left as it was.
    /// A carried login is then saved under `configuration` as well, signed in, as after a restore: it stays there
    /// until a sign-out or a purge made with this configuration, whatever is done under the previous one.
    ///
    /// - Throws: `AmplifyCognitoClientError.storageUnavailable` if storage could not be read or written, and
    ///   `storageUnavailable(.interrupted)` if the record kept changing under the call;
    ///   `AmplifyCognitoClientError.unknown` if the saved record, or `.default`'s saved label, is one this version cannot
    ///   read; `AmplifyCognitoClientError.sessionConfigurationMismatch` if a client for this session is live in this process
    ///   with a different user pool or identity pool (that client labels its own configuration's row; release it
    ///   to label this one); `CancellationError` if the calling task is cancelled while it waits for the session's
    ///   restore or record.
    static func setSessionLabel(
        _ label: String?,
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String? = nil
    ) async throws {
        try await setSessionLabel(
            label,
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
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String?,
        includingSignedOut: Bool,
        dependencies: SessionCoreDependencies
    ) async throws -> [AmplifyCognitoClientStoredSession] {
        // No gate: each record read is atomic, and every write commits before its operation returns.
        // Live sessions are not overlaid; the listing is what is saved.
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let io = SessionRecordIO(store: dependencies.makeStore(namespace), queue: SessionRecordIO.listingQueue)
        return try await io.storedSessions(
            includingSignedOut: includingSignedOut,
            sweepingChallengesAt: dependencies.now(),
            pluginConfiguration: AuthConfiguration(client: configuration)
        )
    }

    static func purgeStoredSession(
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
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
            // `.default`: the Auth plugin's configuration-change rule first, when it carries.
            try await applyPluginConfigurationRule(sessionId, configuration, store, dependencies)
            try await store.purge(sessionId)
            dependencies.gates.memory(for: namespace, sessionId: sessionId).reset()
            return nil
        }
        if let live {
            try await live.purgeStoredRecord()
        }
    }

    static func setSessionLabel(
        _ label: String?,
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String?,
        dependencies: SessionCoreDependencies
    ) async throws {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let gate = dependencies.gates.gate(for: namespace, sessionId: sessionId)
        let store = SessionRecordIO(store: dependencies.makeStore(namespace), queue: gate.ioQueue)
        // As for a purge: whether a live session owns the record is decided under the gate, and a label written
        // here is what a session built meanwhile restores.
        let live = try await withSessionGates(sessionId, namespace, dependencies) { () -> SessionCore? in
            if let live = liveSession(sessionId, in: namespace, dependencies: dependencies) {
                return live
            }
            // What a restore would carry here is carried first, as the static sign-out carries it. For a named
            // session, a labelled row written where nothing is saved yet would stop that carry, and the session would
            // restore signed out; for `.default`, the label is then bound to the user the carried record holds.
            try await applyPluginConfigurationRule(sessionId, configuration, store, dependencies)
            _ = try await store.perform { try $0.readCarryingForward(sessionId) }
            _ = try await store.setLabel(label, for: sessionId)
            return nil
        }
        if let live {
            try await live.setSessionLabel(label)
        }
    }

    static func signOutStoredSession(
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String?,
        options: AmplifyCognitoClientSignOutOptions = AmplifyCognitoClientSignOutOptions(),
        dependencies: SessionCoreDependencies
    ) async -> AmplifyCognitoClientSignOutResult {
        do {
            return try await routedSignOutStoredSession(
                sessionId: sessionId,
                configuration: configuration,
                accessGroup: accessGroup,
                options: options,
                dependencies: dependencies
            )
        } catch {
            // Thrown before anything was cleared: the session is still signed in. For `.default` the plugin's
            // configuration-change rule may have copied a login here first, but it never deletes in this call.
            return .failed(SessionSignOut.failure(error))
        }
    }

    /// `signOutStoredSession`, throwing what happened before anything was cleared; the caller maps it to `.failed`.
    private static func routedSignOutStoredSession(
        sessionId: AmplifyCognitoClientSessionID,
        configuration: AmplifyCognitoClientConfiguration,
        accessGroup: String?,
        options: AmplifyCognitoClientSignOutOptions,
        dependencies: SessionCoreDependencies
    ) async throws -> AmplifyCognitoClientSignOutResult {
        let namespace = SessionStorageNamespace(pools: configuration.poolNamespace, accessGroup: accessGroup)
        let gate = dependencies.gates.gate(for: namespace, sessionId: sessionId)
        let store = SessionRecordIO(store: dependencies.makeStore(namespace), queue: gate.ioQueue)
        let revoker = dependencies.makeRevoker(configuration)

        enum Routed: Sendable {
            case live(SessionCore)
            case done(AmplifyCognitoClientSignOutResult)
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
            // signed out (and revoked) here, not restored signed in later: for `.default`, by the Auth plugin's rule,
            // which is applied only when it carries, and records no configuration.
            let carried = try await applyPluginConfigurationRule(sessionId, configuration, store, dependencies)
            _ = try await store.perform { try $0.readCarryingForward(sessionId) }
            let outcome = try await SessionSignOut(
                sessionId: sessionId,
                store: store,
                describe: { PluginRecordSummary.peek($0).credentialSummary },
                global: options.globalSignOut,
                revoke: { payload, firstAttempt in
                    // No window here, so the hosted UI's sign-out never runs; when it would have, the cookie
                    // it leaves in the browser is reported.
                    var outcome = try await revoker.revoke(payload, global: options.globalSignOut)
                    if firstAttempt, revoker.signOutPresentsBrowser(payload) {
                        outcome.hostedUIError = outcome.hostedUIError ?? SessionCore.noSignOutWindow()
                    }
                    return outcome
                },
                revokeCopy: { payload in
                    try await revoker.revoke(payload, global: false)
                }
            ).run()
            if outcome.endedSession {
                dependencies.gates.memory(for: namespace, sessionId: sessionId).reset()
            }
            if outcome.removedCredentials, case .carried(let source, let bytes)? = carried {
                await SessionCore.signOutCarrySource(source, carried: bytes, through: store)
            }
            if options.purgeStoredSession, outcome.endedSession {
                do {
                    try await store.purge(sessionId)
                } catch {
                    // Signed out, but the row is kept: `.partial` with the purge's failure, as a live session's.
                    return .done(outcome.server.signedOutResult(
                        storageError: SessionCore.rowNotRemoved(sessionId, error)
                    ))
                }
            }
            return .done(outcome.result())
        }
        switch routed {
        case .live(let core):
            return await core.signOut(global: options.globalSignOut, purge: options.purgeStoredSession)
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
    /// - Throws: `AmplifyCognitoClientError.sessionConfigurationMismatch` if the session is live in this process under any
    ///   other pool configuration in the same access group: its records are that session's to change, through a
    ///   client with its configuration. `storageUnavailable` if the marker could not be read, or kept changing.
    private static func withSessionGates<T: Sendable>(
        _ sessionId: AmplifyCognitoClientSessionID,
        _ namespace: SessionStorageNamespace,
        _ dependencies: SessionCoreDependencies,
        _ body: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let reader = SessionRecordIO(store: dependencies.makeStore(namespace), queue: SessionRecordIO.listingQueue)
        @Sendable func named() async throws -> Set<SessionStorageNamespace> {
            let pools: [PoolNamespace]
            if sessionId == .default {
                // `.default` keeps no marker: the namespace of the Auth plugin's last configuration, which its rule
                // carries from or deletes in.
                pools = try await reader.perform { try $0.pluginConfigurationSource() }.map { [$0] } ?? []
            } else {
                let marker = try await reader.perform { try $0.marker(for: sessionId) }
                let components = (marker?.copies.map(\.poolNamespace) ?? []) + [marker?.poolNamespace].compactMap { $0 }
                pools = components.compactMap(PoolNamespace.init(keyComponent:))
            }
            return Set(pools.map {
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
                    throw AmplifyCognitoClientError.sessionConfigurationMismatch(
                        sessionId,
                        "Session \"\(sessionId)\" is in use with a different user pool or identity pool, whose saved records this call would change.",
                        "Make this call through a client with that session's configuration."
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
        throw AmplifyCognitoClientError.storageUnavailable(
            .interrupted,
            "Session \"\(sessionId)\"'s namespace marker kept changing.",
            "Retry the operation."
        )
    }

    /// For `.default`, the Auth plugin's configuration-change rule (`SessionCore.applyPluginConfigurationRule`), under
    /// the gates `withSessionGates` holds, **only when it carries**, and **never recording the configuration**:
    /// this call may be made with a configuration other than the app's, so it never deletes or revokes the
    /// app's login, and only a restore records a configuration. Returns what the rule did (`nil` for a named
    /// session): a sign-out then signs out the record a carry came from; a purge and a label leave it.
    @discardableResult
    private static func applyPluginConfigurationRule(
        _ sessionId: AmplifyCognitoClientSessionID,
        _ configuration: AmplifyCognitoClientConfiguration,
        _ store: SessionRecordIO,
        _ dependencies: SessionCoreDependencies
    ) async throws -> SessionRecordStore.PluginConfigurationOutcome? {
        guard sessionId == .default else {
            return nil
        }
        return try await SessionCore.applyPluginConfigurationRule(
            through: store,
            current: AuthConfiguration(client: configuration),
            heldSource: nil,
            onlyIfCarrying: true,
            makeRevoker: dependencies.makePreviousConfigurationRevoker
        )
    }

    /// The live session for `sessionId`, if it reads this namespace's record. A live session for the same
    /// ID on another namespace is a different record, behind a different gate, and is left alone.
    private static func liveSession(
        _ sessionId: AmplifyCognitoClientSessionID,
        in namespace: SessionStorageNamespace,
        dependencies: SessionCoreDependencies
    ) -> SessionCore? {
        guard let live = dependencies.registry.liveSession(for: sessionId), live.namespace == namespace else {
            return nil
        }
        return live.session
    }
}
