//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAWSCognitoAuth

/// One live session: its in-memory state, its streams, its engine and its SDK clients.
///
/// There is exactly one per session ID in a process. The registry holds it weakly; handles and
/// providers hold it strongly, and so does any restore or refresh in flight. When the last of them goes
/// it is released, which ends both streams, frees the engine and the SDK clients, and schedules the
/// registry prune.
///
/// **It never performs keychain I/O on itself, nor on the cooperative pool.** It holds in-memory state
/// only. Every store call is serialized by the record's gate rather than by this actor, runs on the
/// record's I/O queue (`SessionRecordIO`), and then hops onto the actor with one short synchronous call
/// (`apply`) to swap the snapshot and publish. A slow keychain therefore blocks neither the actor nor a
/// cooperative thread: waiters, timers, synchronous accessors and stream subscriptions stay responsive,
/// which is what makes the restore bound real even when every cooperative thread is busy.
actor SessionCore {

    // Immutable and Sendable, so synchronously readable from any context.
    nonisolated let sessionId: SessionID
    nonisolated let configuration: AuthClientConfiguration
    nonisolated let namespace: SessionStorageNamespace
    nonisolated let clients: CognitoServiceClients
    /// Only ever used off the actor.
    nonisolated let store: SessionRecordStore
    /// This record's async mutex, held strongly so the static calls find the same one.
    nonisolated let gate: SessionRecordGate
    /// Every record's gate: a restore that carries the session forward also holds the source namespace's.
    nonisolated let gates: SessionRecordGates
    /// When a carried session waiting for its identity may try the identity step again, and what answers until then.
    /// Per record, for the process: shared by every core of this record (`SessionRecordGates.memory`).
    nonisolated let identityRetry: PendingIdentityRetry
    /// The last refresh told its token was reused with the record unchanged (`refreshOnce`, step 3). Per record, for
    /// the process, as `identityRetry`.
    nonisolated let refreshTokenReuse: RefreshTokenReuse
    /// Serializes this session's sign-in steps. See `SessionCore+SignIn`.
    nonisolated let signInLock = SessionRecordGate()
    /// One per session; holds multi-step sign-in progress.
    nonisolated let engine: any SessionEngine
    nonisolated let events = SessionEventStream<AuthEvent>()
    nonisolated let states = SessionEventStream<AuthSessionState>()
    nonisolated let restoreFlight = SingleFlight<SessionSnapshot>()
    /// One flight per kind of operation, because a flight's joiners take its result whatever they asked
    /// for: a refresh when the credentials need one, ...
    nonisolated let refreshFlight = SingleFlight<SessionSnapshot>()
    /// ... a refresh whatever the credentials' expiry (`fetchAuthSession(forceRefresh: true)`), ...
    nonisolated let forcedRefreshFlight = SingleFlight<SessionSnapshot>()
    /// ... and guest acquisition on a signed-out session. All three take the record's gate, so they
    /// serialize against each other; each re-reads first, so a later one builds on an earlier one.
    nonisolated let guestFlight = SingleFlight<SessionSnapshot>()
    nonisolated let bounds: SessionCoreDependencies.Bounds
    nonisolated let now: @Sendable () -> Date
    /// Revokes a login `.default`'s configuration-change rule deleted (`SessionCore+PluginConfiguration.swift`).
    nonisolated let makePreviousConfigurationRevoker: @Sendable (AuthConfiguration) -> any SessionRevoker
    private nonisolated let registry: SessionCoreDependencies.Registry
    /// Whether this core has logged the temporary warning that `.default`'s shared record holds another principal
    /// (`SessionCore+SharedRecordWarning.swift`): once per core. Goes with the plugin bridge.
    nonisolated let sharedRecordWarning = SharedRecordWarningLatch()
    #if os(iOS) || os(macOS) || os(visionOS)
    /// The process-wide system-sheet lock: held around this session's
    /// hosted-UI sign-in and the first attempt of a sign-out that shows the logout page.
    nonisolated let sheetLock: SystemSheetLock
    /// `SessionCoreDependencies.afterLogoutStop`: a test seam, a no-op in the app.
    nonisolated let afterLogoutStop: @Sendable (SessionID) async -> Void
    #endif

    // Mutable, in memory only.

    /// `nil` until a restore succeeds, or a write lands.
    private var snapshot: SessionSnapshot?

    /// The sign-in step the session is waiting on, as last reported by the engine.
    private(set) var pendingChallenge: AuthClientSignInStep?

    /// Bumped whenever `pendingChallenge` is set, so a reader that suspended can tell it went stale.
    private(set) var challengeGeneration: UInt64 = 0

    /// Which sign-in attempt the session is on. Bumped by every new `signIn` and by everything that
    /// cancels a pending sign-in (sign-out, purge, deletion). A sign-in step captures it when it starts,
    /// and neither commits nor publishes its challenge once it has moved: the session has since been
    /// signed out, or a newer sign-in owns it.
    private(set) var signInEpoch: UInt64 = 0

    /// How many times a sign-out, purge or deletion has ended the session, cancelling any sign-in.
    /// Unlike `signInEpoch`, a new sign-in does not move it. A sign-in reads it before it queues for the
    /// sign-in lock, and gives up if it moved by the time it holds the lock.
    private(set) var sessionEndings: UInt64 = 0

    /// The last state sent on `states`, to send only changes.
    private var lastPublished: AuthSessionState?

    /// Set when a refresh proved the refresh token dead. Cleared when the credentials change.
    private(set) var isExpired = false

    /// Whether a hosted-UI sign-in call of this session is in progress, from before it waits for the
    /// sign-in lock until it returns: a second call (a double tap) is refused at once rather than queued
    /// behind it, where it would show a browser of its own once the first ended.
    private var webUISignInInFlight = false

    /// How to stop this session's hosted-UI sign-in, and the sign-in epoch it belongs to: a sign-out, purge or
    /// deletion stops it only if it began before the epoch that ending moves to, so a later flow is never
    /// interrupted by an earlier ending.
    private var webUIFlow: (epoch: UInt64, cancel: @Sendable () -> Void)?

    /// How to stop this session's passkey registrations in flight: a sign-out, purge or deletion stops
    /// every one registered before it. Associate is not a sign-in step, so no epoch scopes it.
    private var passkeyRegistrations: [UInt64: @Sendable () -> Void] = [:]
    private var nextPasskeyRegistration: UInt64 = 0

    /// Builds a core. Runs under the registry lock, inside the client's synchronous `init`: cheap, no
    /// `await`, no keychain call, no call back into the registry.
    init(
        sessionId: SessionID,
        configuration: AuthClientConfiguration,
        namespace: SessionStorageNamespace,
        clients: CognitoServiceClients,
        dependencies: SessionCoreDependencies
    ) throws {
        self.sessionId = sessionId
        self.configuration = configuration
        self.namespace = namespace
        self.clients = clients
        self.store = dependencies.makeStore(namespace)
        self.gate = dependencies.gates.gate(for: namespace, sessionId: sessionId)
        self.gates = dependencies.gates
        let memory = dependencies.gates.memory(for: namespace, sessionId: sessionId)
        self.identityRetry = memory.identityRetry
        self.refreshTokenReuse = memory.refreshTokenReuse
        self.engine = try dependencies.makeEngine(SessionEngineContext(
            sessionId: sessionId,
            configuration: configuration,
            namespace: namespace,
            clients: clients
        ))
        self.bounds = dependencies.bounds
        self.now = dependencies.now
        self.makePreviousConfigurationRevoker = dependencies.makePreviousConfigurationRevoker
        self.registry = dependencies.registry
        #if os(iOS) || os(macOS) || os(visionOS)
        self.sheetLock = dependencies.sheetLock
        self.afterLogoutStop = dependencies.afterLogoutStop
        #endif
    }

    deinit {
        // Ends every `for await` loop over this session's streams.
        events.finish()
        states.finish()
        // Never synchronously: this deinit can run while the registry's lock is held, when a lookup's
        // temporary strong reference turns out to be the last one. The prune compares before it
        // clears, so it is harmless whenever it runs.
        let registry = registry
        let sessionId = sessionId
        Task { registry.pruneIfReleased(sessionId) }
    }

    // MARK: In-memory state. Synchronous and actor-isolated: nothing here touches storage.

    /// The snapshot, once a restore has succeeded or a write has landed.
    var restoredSnapshotIfAny: SessionSnapshot? {
        snapshot
    }

    /// The snapshot and whether the refresh token is known dead, read in one hop so they agree.
    var snapshotAndExpiry: (SessionSnapshot, Bool) {
        (snapshot ?? .absent, isExpired)
    }

    /// The current state, or `nil` before the first restore.
    var currentState: AuthSessionState? {
        snapshot.map { $0.state(engine: engine, challenge: pendingChallenge) }
    }

    enum ChallengeUpdate: Sendable {
        case unchanged
        case set(AuthClientSignInStep?)
    }

    /// Installs a snapshot read or written by an operation, publishes the state it projects to if that
    /// changed, then sends `event` if there is one. Events are never de-duplicated.
    ///
    /// Every mutation path ends here, after its storage commit and before the operation returns, so a
    /// caller that awaited an operation has already caused its event.
    @discardableResult
    func apply(
        _ newSnapshot: SessionSnapshot,
        challenge update: ChallengeUpdate = .unchanged,
        event: AuthEvent?
    ) -> SessionSnapshot {
        if newSnapshot.credentials != snapshot?.credentials {
            isExpired = false
        }
        snapshot = newSnapshot
        if case .set(let step) = update {
            setChallenge(step)
        }
        publish(newSnapshot.state(engine: engine, challenge: pendingChallenge))
        if let event {
            events.send(event)
        }
        return newSnapshot
    }

    /// Adopts a restored snapshot, unless something already installed one meanwhile, which wins.
    ///
    /// `pending` is the engine's challenge, read across a suspension that began at `generation`. If the
    /// session's challenge was set since then, the newer one is kept rather than overwritten.
    func adoptRestored(
        _ restored: SessionSnapshot,
        challenge pending: AuthClientSignInStep?,
        readAtChallengeGeneration generation: UInt64
    ) -> SessionSnapshot {
        if let snapshot {
            return snapshot
        }
        let update: ChallengeUpdate = generation == challengeGeneration ? .set(pending) : .unchanged
        return apply(restored, challenge: update, event: nil)
    }

    /// Publishes a failed restore. Not cached: the snapshot stays `nil`, so the next operation tries a
    /// fresh restore.
    func restoreFailed(_ reason: StorageUnavailableReason) {
        guard snapshot == nil else {
            return
        }
        publish(.unavailable(reason))
    }

    /// Records the sign-in step the session now waits on (`nil` when none). The sign-in paths of task
    /// 2.5 call this; two different steps both publish.
    func setPendingChallenge(_ step: AuthClientSignInStep?) {
        guard let snapshot else {
            setChallenge(step)
            return
        }
        apply(snapshot, challenge: .set(step), event: nil)
    }

    /// Starts a new sign-in attempt, superseding any earlier one.
    func beginSignInAttempt() -> UInt64 {
        signInEpoch &+= 1
        return signInEpoch
    }

    /// Cancels the session's pending sign-in: moves the epoch first, so a step that finishes from now on
    /// neither commits nor publishes, then tells the engine, which makes a step in flight throw.
    ///
    /// The engine is told which epoch it ends: a sign-in that begins between the two steps, with the new
    /// epoch, is not cancelled by this older sign-out.
    ///
    /// A hosted-UI sign-in of this session holding or queued for the system sheet is stopped too, and its
    /// browser dismissed: the epoch has moved, so it reports the sign-in as
    /// cancelled, and a late result is never committed.
    ///
    /// A passkey registration of this session in flight is stopped too: its sheet closes, and it reports
    /// that the session ended. A sign-in's passkey ceremony is stopped through the engine, which runs it.
    ///
    /// Safe from a cancelled task (a sign-out whose caller gave up): the epoch move and the flow's stop are plain
    /// actor and lock work, and the engine's cancel sends to its machines from tasks of its own
    /// (`LiveSignInSteps.cancelIfSigningIn`), so nothing here is dropped with the caller's cancellation.
    nonisolated func cancelPendingSignIns() async {
        let (epoch, stops) = await moveSignInEpoch()
        for stop in stops {
            stop()
        }
        await engine.cancelPendingSignIn(before: epoch)
    }

    /// Moves the epoch, and takes the hosted-UI flow the move ends and the passkey registrations in flight, in
    /// one actor step, so a flow or registration registered after it is left alone.
    private func moveSignInEpoch() -> (UInt64, [@Sendable () -> Void]) {
        signInEpoch &+= 1
        sessionEndings &+= 1
        var stops: [@Sendable () -> Void] = []
        if let flow = webUIFlow, flow.epoch < signInEpoch {
            stops.append(flow.cancel)
            webUIFlow = nil
        }
        stops += passkeyRegistrations.values
        passkeyRegistrations = [:]
        return (signInEpoch, stops)
    }

    /// Registers a passkey registration in flight, which the session's next ending stops.
    func registerPasskeyRegistration(cancel: @escaping @Sendable () -> Void) -> UInt64 {
        nextPasskeyRegistration &+= 1
        passkeyRegistrations[nextPasskeyRegistration] = cancel
        return nextPasskeyRegistration
    }

    func unregisterPasskeyRegistration(_ id: UInt64) {
        passkeyRegistrations[id] = nil
    }

    /// Stops this session's passkey registrations in flight now, ahead of `cancelPendingSignIns()`: what a
    /// sign-out that shows the hosted UI's logout page does once it holds the system sheet, or to free the sheet a
    /// registration holds, so the page can have it. Each reports that the session ended.
    /// `true` if there was one.
    func stopPasskeyRegistrations() -> Bool {
        let stops = passkeyRegistrations.values
        passkeyRegistrations = [:]
        for stop in stops {
            stop()
        }
        return !stops.isEmpty
    }

    /// Registers the session's hosted-UI flow of `epoch`, which an ending then stops. `false` if the epoch has
    /// already moved: the flow must not start.
    func registerWebUIFlow(epoch: UInt64, cancel: @escaping @Sendable () -> Void) -> Bool {
        guard signInEpoch == epoch else {
            return false
        }
        webUIFlow = (epoch, cancel)
        return true
    }

    func unregisterWebUIFlow(epoch: UInt64) {
        if webUIFlow?.epoch == epoch {
            webUIFlow = nil
        }
    }

    /// `setPendingChallenge(_:)`, unless the sign-in epoch has moved from `epoch`.
    func setPendingChallenge(_ step: AuthClientSignInStep?, ifEpoch epoch: UInt64) {
        guard signInEpoch == epoch else {
            return
        }
        setPendingChallenge(step)
    }

    private func setChallenge(_ step: AuthClientSignInStep?) {
        pendingChallenge = step
        challengeGeneration &+= 1
    }

    /// Claims the session's one hosted-UI sign-in call. `false` if one is already in progress.
    func beginWebUISignIn() -> Bool {
        guard !webUISignInInFlight else {
            return false
        }
        webUISignInInFlight = true
        return true
    }

    func endWebUISignIn() {
        webUISignInInFlight = false
    }

    /// Records that the refresh token is dead. The state does not change: the session stays signed in
    /// as its user, so an app knows whom to re-authenticate, and its operations throw `sessionExpired`.
    func markExpired() {
        guard !isExpired else {
            return
        }
        isExpired = true
        events.send(.sessionExpired)
    }

    private func publish(_ state: AuthSessionState) {
        guard state != lastPublished else {
            return
        }
        lastPublished = state
        states.send(state)
    }

    // MARK: Record access

    /// Runs `body` with the store while holding this record's gate. The body runs off the actor, and its
    /// store calls run on the record's I/O queue, so a blocking keychain call occupies neither the actor
    /// nor a cooperative-pool thread.
    nonisolated func withRecord<T: Sendable>(_ body: @Sendable (SessionRecordIO) async throws -> T) async throws -> T {
        let io = recordIO()
        return try await gate.withLock { try await body(io) }
    }

    /// The record's I/O for `withRecord`. For `.default` only, every record it reads is a re-read, which the core
    /// compares with what it holds (`noteReread`). TEMPORARY: the observer goes with the plugin bridge,
    /// with the warning of `SessionCore+SharedRecordWarning.swift`. A named session's I/O has none.
    nonisolated func recordIO() -> SessionRecordIO {
        guard sessionId == .default else {
            return SessionRecordIO(store: store, queue: gate.ioQueue)
        }
        return SessionRecordIO(store: store, queue: gate.ioQueue, observeRead: { [self] sessionId, result in
            await noteReread(SessionSnapshot(result), of: sessionId)
        })
    }
}
