//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AmplifyFoundation
import AuthenticationServices
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// WebAuthn ceremonies: the sheet lease at each lease point, through the core, over the
/// fake engine, which runs the ceremony through the request's runner where the live engine does. What the
/// lease guards (one sheet per process), what it never holds (the session record, `signInLock` for
/// associate), and who can stop a ceremony (the caller, a sign-out). `LiveWebAuthnCeremonyTests` covers the
/// live engine.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class WebAuthnCeremonyTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Lease points 1 and 3: a sign-in's ceremony

    /// Lease points 1 and 3: a sign-in's ceremony runs under the sheet lease, for its session, and the lease
    /// is free once the sign-in has returned.
    ///
    /// - Given: an engine whose sign-in runs one ceremony through the request's runner and signs in, the
    ///   ceremony held up until the test lets it answer
    /// - When:
    ///    - alice signs in with a window, with `.webAuthn` preferred, and again (after signing out) with no
    ///      preference, as when Cognito answers `WEB_AUTHN` on its own
    /// - Then:
    ///    - while each ceremony is up, the sheet is held by the session; the request carries the window's
    ///      box, and the ceremony runs over it
    ///    - each sign-in returns `.done`, and the sheet is free afterwards
    func testASignInsCeremonyHoldsTheSheetLease() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        engine.scriptSignIn { request, current in
            _ = try await engine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            return .done(payload: FakeSessionEngine.signedIn(request.username, keepingIdentityOf: current).data)
        }

        for (index, flow) in [AuthClientAuthFlowType.userAuth(preferredFirstFactor: .webAuthn), .userAuth(preferredFirstFactor: nil)].enumerated() {
            let held = HeldSheet()
            engine.scriptCeremonyBody { _ in
                try await held.answer()
                return Data("credential".utf8)
            }
            let signIn = Task { @MainActor in
                try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: flow))
            }
            try await held.up()
            let holder = await harness.sheetLock.currentHolder
            XCTAssertEqual(holder, work, "\(flow)")
            await held.letAnswer()

            let result = try await signIn.value(within: 10)
            XCTAssertEqual(result.nextStep, .done)
            let free = await harness.sheetLock.currentHolder
            XCTAssertNil(free)
            let request = try XCTUnwrap(engine.signInCalls.last?.request.webAuthn)
            let holdsWindow = await request.anchor?.holds(window)
            XCTAssertEqual(holdsWindow, true)
            XCTAssertTrue(engine.ceremonyAnchorCalls[index] === request.anchor)
            await client.signOut()
        }
    }

    // MARK: Lease point 2: a confirmation's ceremony

    /// Lease point 2: `confirmSignIn("WEB_AUTHN")` after a first-factor selection runs its ceremony under the
    /// lease, over the sign-in's window, or over its own when it is given one.
    ///
    /// - Given: a sign-in with window A stopped on a selection offering `.webAuthn`, and an engine whose
    ///   confirmation runs a ceremony over the window the seam says it uses, then signs in
    /// - When:
    ///    - the selection is answered with `WEB_AUTHN` without a window; then, after a sign-out and a new
    ///      sign-in with A, with window B
    /// - Then:
    ///    - the first ceremony runs over A's box, the second over B's; each under the sheet held by the session
    ///    - both return `.done`, and the sheet is free afterwards
    func testAConfirmationsCeremonyUsesItsOwnWindowElseTheSignIns() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let windowA = await WebAuthnFixtures.window()
        let windowB = await WebAuthnFixtures.window()
        let lock = harness.sheetLock
        let holders = TestBox<[SessionID?]>([])
        engine.scriptSignIn { _, _ in .challenge(.continueSignInWithFirstFactorSelection([.password, .webAuthn])) }
        engine.scriptConfirmSignIn { request in
            _ = try await engine.runCeremony(request.webAuthn, anchor: engine.webAuthnAnchor(for: request))
            return .done(payload: FakePayload.signedIn("alice").data)
        }
        engine.scriptCeremonyBody { _ in
            let holder = await lock.currentHolder
            holders.with { $0.append(holder) }
            return Data("credential".utf8)
        }

        _ = try await client.signIn(username: "alice", presentationAnchor: windowA)
        let first = try await client.confirmSignIn(challengeResponse: "WEB_AUTHN")
        await client.signOut()
        _ = try await client.signIn(username: "alice", presentationAnchor: windowA)
        let second = try await client.confirmSignIn(challengeResponse: "WEB_AUTHN", presentationAnchor: windowB)

        XCTAssertEqual(first.nextStep, .done)
        XCTAssertEqual(second.nextStep, .done)
        let anchors = engine.ceremonyAnchorCalls
        XCTAssertEqual(anchors.count, 2)
        let firstHoldsA = await anchors.first??.holds(windowA)
        let lastHoldsB = await anchors.last??.holds(windowB)
        XCTAssertEqual(firstHoldsA, true)
        XCTAssertEqual(lastHoldsB, true)
        XCTAssertEqual(holders.value, [work, work])
        let free = await lock.currentHolder
        XCTAssertNil(free)
    }

    // MARK: Lease point 4: associate

    /// Lease point 4: associate runs its ceremony under the sheet lease, and takes no `signInLock`, reads
    /// the session's payload as it is, and writes nothing.
    ///
    /// - Given: `work` signed in as alice, and associate's ceremony held up
    /// - When:
    ///    - `work` associates a passkey with a window; while the sheet is up, `work` signs in and answers a
    ///      challenge
    /// - Then:
    ///    - the sheet is held by `work` during the ceremony
    ///    - the sign-in and the confirmation are answered at once (`invalidState`: signed in, nothing
    ///      pending), so associate does not hold `signInLock`
    ///    - associate returns once the ceremony answers, having sent alice's payload and the window's box;
    ///      the sheet is free, no refresh ran, and the record is unchanged
    func testAssociateHoldsTheSheetLeaseButNotTheSignInLock() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        let before = try harness.storedRecord(work)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data("credential".utf8)
        }

        let associate = Task { @MainActor in try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        let holder = await harness.sheetLock.currentHolder
        XCTAssertEqual(holder, work)
        let signIn = await authClientError { try await client.signIn(username: "alice", password: "password") }
        let confirm = await authClientError { try await client.confirmSignIn(challengeResponse: "123456") }
        XCTAssertEqual(signIn?.kind, .invalidState)
        XCTAssertEqual(confirm?.kind, .invalidState)
        await held.letAnswer()
        try await associate.value(within: 10)

        guard case .associateWebAuthnCredential(let payload, let anchor)? = engine.accountOperationCalls.last else {
            return XCTFail("no associate reached the engine: \(engine.accountOperationCalls)")
        }
        XCTAssertEqual(payload, alice.data)
        let holdsWindow = await anchor?.holds(window)
        XCTAssertEqual(holdsWindow, true)
        let free = await harness.sheetLock.currentHolder
        XCTAssertNil(free)
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(try harness.storedRecord(work), before)
    }

    /// - Given: a signed-out session, a guest session, and a session waiting on a challenge
    /// - When: each associates a passkey
    /// - Then:
    ///    - each throws `notSignedIn`; no engine is called, nothing is refreshed, and the sheet is never taken
    func testAssociateNeedsASignedInUser() async throws {
        try harness.signIn(home, .guest(identityId: "us-east-1:guest"))
        let pendingId = ClientFixtures.id("pending")
        let pending = try harness.client(pendingId)
        let pendingEngine = try XCTUnwrap(harness.engine(for: pendingId))
        pendingEngine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await pending.signIn(username: "alice", password: "password")
        let clients = try [harness.client(work), harness.client(home), pending]
        let window = await WebAuthnFixtures.window()

        for client in clients {
            let error = await authClientError { try await client.associateWebAuthnCredential(presentationAnchor: window) }
            XCTAssertEqual(error?.kind, .notSignedIn)
        }
        for id in [work, home, pendingId] {
            XCTAssertEqual(harness.engine(for: id)?.accountOperationCalls, [], "\(id)")
            XCTAssertEqual(harness.engine(for: id)?.refreshCalls, [], "\(id)")
            XCTAssertEqual(harness.engine(for: id)?.ceremonyAnchorCalls.count, 0, "\(id)")
        }
    }

    /// - Given: a signed-in session whose tokens need a refresh, and the refresh held
    /// - When: two associates run concurrently
    /// - Then:
    ///    - the session refreshes once, and both send the refreshed payload
    func testAssociateRefreshesAStalePayloadOnceForConcurrentCalls() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        let first = Task { @MainActor in try await client.associateWebAuthnCredential(presentationAnchor: window) }
        let second = Task { @MainActor in try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await latch.arrivals(1)
        await waitUntil("both calls wait on the one refresh") { await client.core.refreshFlight.waiterCount == 2 }
        await latch.open()
        // The two ceremonies race for the one sheet: one wins, and the other may be refused as busy.
        let outcomes = await [first.result, second.result]

        XCTAssertEqual(engine.refreshCalls, [stale.data])
        XCTAssertEqual(engine.accountOperationCalls.map(\.payload), [stale.refreshed.data, stale.refreshed.data])
        XCTAssertTrue(outcomes.contains { (try? $0.get()) != nil }, "one associate should succeed")
    }

    /// Associate on one session uses that session only: another session is never refreshed, called or written.
    ///
    /// - Given: `work` signed in as alice, and `home` signed in as bob whose tokens need a refresh
    /// - When:
    ///    - `work` associates a passkey
    /// - Then:
    ///    - `work`'s engine gets alice's payload; `home`'s engine gets no call and no refresh, and `home`'s record is
    ///      unchanged
    func testAssociateOnOneSessionNeverTouchesAnother() async throws {
        let alice = FakePayload.signedIn("alice")
        try harness.signIn(work, alice)
        try harness.signIn(home, .signedIn("bob", stale: true))
        let homeBefore = try harness.storedRecord(home)
        let client = try harness.client(work)
        _ = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let other = try XCTUnwrap(harness.engine(for: home))
        let window = await WebAuthnFixtures.window()

        try await client.associateWebAuthnCredential(presentationAnchor: window)

        XCTAssertEqual(engine.accountOperationCalls.map(\.payload), [alice.data])
        XCTAssertEqual(other.accountOperationCalls, [])
        XCTAssertEqual(other.refreshCalls, [])
        XCTAssertEqual(try harness.storedRecord(home), homeBefore)
    }

    // MARK: One sheet per process

    /// A second ceremony, from another session, while one holds the sheet is refused at once.
    ///
    /// - Given: `work` (alice) and `home` (bob) signed in, and `work`'s associate ceremony held up
    /// - When:
    ///    - `home` associates a passkey, and `home` signs in (after signing out) with a WebAuthn ceremony
    /// - Then:
    ///    - both throw `.browserBusy(holder: work)`, and neither of `home`'s ceremonies ran
    ///    - `work`'s associate then completes, and the sheet is free
    func testASecondCeremonyWhileOneHoldsTheSheetIsBusy() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let homeEngine = try XCTUnwrap(harness.engine(for: home))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }
        homeEngine.scriptSignIn { request, _ in
            _ = try await homeEngine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            return .done(payload: FakePayload.signedIn("bob").data)
        }

        let associate = Task { @MainActor in try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        let busyAssociate = await authClientError { try await homeClient.associateWebAuthnCredential(presentationAnchor: window) }
        await homeClient.signOut()
        let busySignIn = await authClientError {
            try await homeClient.signIn(
                username: "bob",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        await held.letAnswer()
        try await associate.value(within: 10)

        XCTAssertEqual(busyAssociate?.kind, .browserBusy(holder: work))
        XCTAssertEqual(busySignIn?.kind, .browserBusy(holder: work))
        XCTAssertEqual(homeEngine.ceremonyAnchorCalls.count, 0)
        let free = await harness.sheetLock.currentHolder
        XCTAssertNil(free)
    }

    // MARK: Who can stop a ceremony

    /// A sign-out during a held sign-in ceremony stops it through the engine, and does not wait for
    /// the sign-in's `signInLock`.
    ///
    /// - Given: alice signing in with a window, her ceremony up, and an engine that, once its ceremony
    ///   fails, waits for the test before it returns (so the sign-in keeps `signInLock` meanwhile)
    /// - When:
    ///    - the session signs out
    /// - Then:
    ///    - the sign-out returns while the sign-in still holds `signInLock`, the ceremony was cancelled, and
    ///      the sheet is free once it has unwound
    ///    - the sign-in then throws the core's sign-in-cancelled `invalidState`, and the session is signed out
    func testASignOutStopsAHeldSignInCeremonyWithoutWaitingForTheSignIn() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        let unwound = Gate(isOpen: true)
        let returnGate = Gate()
        let cancelledCeremony = TestBox(false)
        engine.scriptCeremonyBody { _ in
            do {
                try await held.answer()
            } catch {
                cancelledCeremony.with { $0 = true }
                throw error
            }
            return Data()
        }
        engine.scriptSignIn { request, _ in
            do {
                _ = try await engine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            } catch {
                await unwound.pass()
                await returnGate.pass()
                throw error
            }
            return .done(payload: FakePayload.signedIn("alice").data)
        }

        let signIn = Task { @MainActor in
            try await client.signIn(
                username: "alice",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        try await held.up()
        await client.signOut()
        try await unwound.arrivals(1)

        XCTAssertFalse(signIn.isCancelled)
        await waitUntil("the cancelled ceremony has unwound and freed the sheet") {
            await self.harness.sheetLock.currentHolder == nil
        }
        XCTAssertTrue(cancelledCeremony.value)
        await returnGate.open()
        let error = await authClientError { try await signIn.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// The caller cancelling its own sign-in closes the sheet, and the call throws `CancellationError`.
    ///
    /// - Given: alice signing in with a window, her ceremony up
    /// - When:
    ///    - the calling task is cancelled
    /// - Then:
    ///    - the sign-in throws `CancellationError`, the ceremony saw the cancellation, nothing is pending, and
    ///      the sheet is free
    func testTheCallerCancellingASignInClosesItsSheet() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        let cancelledCeremony = TestBox(false)
        engine.scriptCeremonyBody { _ in
            do {
                try await held.answer()
            } catch {
                cancelledCeremony.with { $0 = true }
                throw error
            }
            return Data()
        }
        engine.scriptSignIn { request, _ in
            _ = try await engine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            return .done(payload: FakePayload.signedIn("alice").data)
        }

        let signIn = Task { @MainActor in
            try await client.signIn(
                username: "alice",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        try await held.up()
        signIn.cancel()

        await assertThrowsAsync({ try await signIn.value(within: 10) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await waitUntil("the cancelled ceremony has unwound and freed the sheet") {
            await self.harness.sheetLock.currentHolder == nil
        }
        XCTAssertTrue(cancelledCeremony.value)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// A caller cancelled before its ceremony starts never shows a sheet (the stop is sticky).
    ///
    /// - Given: alice signing in with a window, held in the engine before its ceremony
    /// - When:
    ///    - the calling task is cancelled, then the engine is let go and asks for its ceremony
    /// - Then:
    ///    - the ceremony is refused before the lease: its body never runs, and the sheet is never taken
    ///    - the sign-in throws `CancellationError`
    func testACallerCancelledBeforeTheCeremonyShowsNothing() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let latch = Gate()
        let holders = TestBox<[SessionID?]>([])
        let lock = harness.sheetLock
        engine.holdSignIns(on: latch)
        engine.scriptSignIn { request, _ in
            let holder = await lock.currentHolder
            holders.with { $0.append(holder) }
            _ = try await engine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            return .done(payload: FakePayload.signedIn("alice").data)
        }

        let signIn = Task { @MainActor in
            try await client.signIn(
                username: "alice",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        try await latch.arrivals(1)
        signIn.cancel()
        await latch.open()

        await assertThrowsAsync({ try await signIn.value(within: 10) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
        XCTAssertEqual(holders.value, [nil])
        let free = await lock.currentHolder
        XCTAssertNil(free)
    }

    /// The caller cancelling a sign-in whose step runs no ceremony changes nothing: it ends as it would have.
    ///
    /// - Given: alice signing in with a window and a password, held in the engine, which signs in without a
    ///   ceremony
    /// - When:
    ///    - the calling task is cancelled, then the engine is let go
    /// - Then:
    ///    - the sign-in returns `.done` (the sign-in rule: once sent, a sign-in runs to its end)
    func testTheCallerCancellingASignInWithoutACeremonyChangesNothing() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let latch = Gate()
        engine.holdSignIns(on: latch)

        let signIn = Task { @MainActor in
            try await client.signIn(username: "alice", password: "password", presentationAnchor: window)
        }
        try await latch.arrivals(1)
        signIn.cancel()
        await latch.open()

        let result = try await signIn.value(within: 10)
        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
    }

    /// A caller that cancels after its ceremony has finished gets the step's real answer.
    ///
    /// - Given: alice signing in with a window; her ceremony completes, then the engine waits on the test before
    ///   answering, as `RespondToAuthChallenge` does after the sheet
    /// - When:
    ///    - the calling task is cancelled while the engine waits, then the engine fails with `.notAuthorized`
    /// - Then:
    ///    - the sign-in throws that `.notAuthorized`, not `CancellationError`: the stop reached no ceremony
    func testACallerCancelAfterTheCeremonyKeepsTheStepsError() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let responding = Gate()
        engine.scriptSignIn { request, _ in
            _ = try await engine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            await responding.pass()
            throw AuthClientError.notAuthorized("Incorrect credential.", "Sign in again.")
        }

        let signIn = Task {
            try await client.signIn(
                username: "alice",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        try await responding.arrivals(1)
        signIn.cancel()
        await responding.open()

        let error = await authClientError { try await signIn.value(within: 10) }
        XCTAssertEqual(error?.kind, .notAuthorized)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 1)
    }

    // MARK: A session ending, and the app's sheet tools

    /// A sign-out during associate's sheet ends the registration as the session ending, not as the caller's
    /// cancellation (the hosted UI's rule for a sign-in the session ended).
    ///
    /// - Given: `work` signed in as alice, her associate's sheet up
    /// - When:
    ///    - `work` signs out
    /// - Then:
    ///    - associate throws `passkeyRegistrationEnded()`, an `invalidState`; its ceremony saw the cancellation,
    ///      and the sheet is free once it has unwound
    func testASignOutEndsAHeldAssociate() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        let cancelledCeremony = TestBox(false)
        engine.scriptCeremonyBody { _ in
            do {
                try await held.answer()
            } catch {
                cancelledCeremony.with { $0 = true }
                throw error
            }
            return Data()
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        await client.signOut()

        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        await waitUntil("the cancelled ceremony has unwound and freed the sheet") {
            await self.harness.sheetLock.currentHolder == nil
        }
        XCTAssertTrue(cancelledCeremony.value)
    }

    /// A sign-out while associate has not reached its sheet yet ends it too, and no sheet is ever shown.
    ///
    /// - Given: `work` signed in, and associate held at `StartWebAuthnRegistration`, before its ceremony
    /// - When:
    ///    - `work` signs out, then `StartWebAuthnRegistration` answers
    /// - Then:
    ///    - associate throws `passkeyRegistrationEnded()`, and its ceremony never runs
    func testASignOutBeforeAssociatesSheetShowsNothing() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let start = Gate()
        engine.scriptAccountOperation(.associateWebAuthnCredential) { _ in
            await start.pass()
            return ()
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await start.arrivals(1)
        await client.signOut()
        await start.open()

        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
        let free = await harness.sheetLock.currentHolder
        XCTAssertNil(free)
    }

    /// Another session's sign-out leaves a session's associate alone.
    ///
    /// - Given: `work` (alice) and `home` (bob) signed in, and `work`'s associate sheet up
    /// - When:
    ///    - `home` signs out, then `work`'s sheet answers
    /// - Then:
    ///    - `work`'s associate completes
    func testAnotherSessionsSignOutLeavesAssociateAlone() async throws {
        try harness.signIn(work, .signedIn("alice"))
        try harness.signIn(home, .signedIn("bob"))
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        await homeClient.signOut()
        await held.letAnswer()

        try await associate.value(within: 10)
    }

    /// `cancelWebUISignIn()` and the sheet lock's `reset()` (what `resetSystemSheet()` calls) close a passkey
    /// sheet as the user closing it, as they close the hosted UI's browser.
    ///
    /// - Given: `work` signed in, its associate's sheet up; then, after that, `home` signing in with a passkey,
    ///   its sheet up
    /// - When:
    ///    - `work` calls `cancelWebUISignIn()`; then the lock is reset while `home`'s sheet is up
    /// - Then:
    ///    - both calls throw `passkeySheetClosed()`, a `.userCancelled`; the sheet is free after each, and
    ///      `home` is left signed out with nothing pending
    func testTheAppsSheetToolsClosePasskeySheetsAsUserCancelled() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let homeEngine = try XCTUnwrap(harness.engine(for: home))
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }
        let homeHeld = HeldSheet()
        homeEngine.scriptCeremonyBody { _ in
            try await homeHeld.answer()
            return Data()
        }
        homeEngine.scriptSignIn { request, _ in
            _ = try await homeEngine.runCeremony(request.webAuthn, anchor: request.webAuthn?.anchor)
            return .done(payload: FakePayload.signedIn("bob").data)
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        await client.cancelWebUISignIn()
        let associateError = await authClientError { try await associate.value(within: 10) }
        await waitUntil("the sheet is free after cancelWebUISignIn") { await self.harness.sheetLock.currentHolder == nil }

        let signIn = Task {
            try await homeClient.signIn(
                username: "bob",
                presentationAnchor: window,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
            )
        }
        try await homeHeld.up()
        let holder = await harness.sheetLock.reset()
        let signInError = await authClientError { try await signIn.value(within: 10) }

        XCTAssertEqual(associateError?.kind, .userCancelled)
        XCTAssertEqual(associateError?.errorDescription, SessionCore.passkeySheetClosed().errorDescription)
        XCTAssertEqual(holder, home)
        XCTAssertEqual(signInError?.kind, .userCancelled)
        XCTAssertEqual(signInError?.errorDescription, SessionCore.passkeySheetClosed().errorDescription)
        let free = await harness.sheetLock.currentHolder
        XCTAssertNil(free)
        let state = await homeClient.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }
}
#endif
