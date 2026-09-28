//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

#if os(iOS) || os(macOS) || os(visionOS)

/// The hosted UI's sign-out over the fake engine and the harness's own sheet lock: every combination of
/// shared cookies, window and lease, the first-attempt-only `.present`, and the static and anchor-less paths.
final class WebUISignOutTests: XCTestCase {

    private var harness: ClientHarness!
    private var window: AuthClientPresentationAnchor!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() async throws {
        harness = ClientHarness()
        window = await HostedUIFixtures.window()
    }

    override func tearDown() async throws {
        let holder = await harness.sheetLock.currentHolder
        XCTAssertNil(holder, "a test left the sheet held")
        await harness.waitForBaseline()
        harness = nil
        window = nil
    }

    private func client(
        _ sessionId: SessionID,
        configuration: AuthClientConfiguration = HostedUIFixtures.configuration
    ) throws -> AmplifyCognitoClient {
        try harness.client(sessionId, configuration: configuration)
    }

    private func signOut(
        _ client: AmplifyCognitoClient,
        options: AuthClientSignOutOptions = AuthClientSignOutOptions()
    ) async throws -> AuthClientSignOutResult {
        let window = window!
        return try await client.signOut(presentationAnchor: window, options: options)
    }

    /// The plan the engine got, without the box (boxes compare by identity).
    private func plans(_ engine: FakeSessionEngine) -> [String] {
        engine.revokeHostedUIPlans.map { plan in
            if case .present = plan {
                return "present"
            }
            return "skip"
        }
    }

    private func hostedUIError(_ result: AuthClientSignOutResult) -> AuthClientError? {
        guard case .partial(let partial) = result else {
            return nil
        }
        return partial.hostedUIError
    }

    // MARK: Cookies, window and lease

    /// - Given: a session whose sign-in did not share the browser's cookies (a password sign-in, and an
    ///   ephemeral hosted-UI sign-in)
    /// - When: each is signed out with a window
    /// - Then:
    ///    - no lease is taken, the engine skips the hosted UI, and the result is `.complete`
    func testASignInThatSharedNoCookiesShowsNothing() async throws {
        for (sessionId, payload) in [(work, FakePayload.signedIn("alice")), (home, HostedUIFixtures.hostedUIPayload(ephemeral: true))] {
            try harness.signIn(sessionId, payload)
            let client = try client(sessionId)
            let engine = try XCTUnwrap(harness.engine(for: sessionId))
            let lock = harness.sheetLock
            engine.scriptHostedUIRevoke { _, _, _ in
                let holder = await lock.currentHolder
                XCTAssertNil(holder)
                return .complete
            }

            let result = try await signOut(client)

            XCTAssertEqual(result, .complete)
            XCTAssertEqual(plans(engine), ["skip"])
        }
    }

    /// - Given: a session whose hosted-UI sign-in shared the browser's cookies, a window, a hosted UI, a free sheet
    /// - When: it is signed out with the window, globally
    /// - Then:
    ///    - the engine presents in that window while the session holds the sheet; the result is `.complete`,
    ///      the session is signed out, and the sheet is free
    func testASharedCookieSignInPresentsTheLogoutUnderTheLease() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let work = work
        engine.scriptHostedUIRevoke { _, global, _ in
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            XCTAssertTrue(global)
            return .complete
        }

        let result = try await signOut(client, options: AuthClientSignOutOptions(globalSignOut: true))

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        let presented = try XCTUnwrap(engine.revokeHostedUIPlans.first)
        guard case .present(let box) = presented else {
            return XCTFail("expected .present")
        }
        let anchor = await MainActor.run { box.anchor }
        XCTAssertTrue(anchor === window)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let holder = await lock.currentHolder
        XCTAssertNil(holder)
    }

    /// The session's own passkey registration, holding the sheet, does not keep the logout page
    /// from showing.
    ///
    /// - Given: a shared-cookie session, whose passkey registration's sheet is up
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the registration is stopped first: it throws `passkeyRegistrationEnded()`, and its ceremony saw the
    ///      cancellation
    ///    - the logout page is presented, under the sheet the session holds once the passkey sheet has closed;
    ///      the result is `.complete`, not `.partial` with `browserBusy`, and the session is signed out
    func testASignOutClosesTheSessionsOwnPasskeySheetAndShowsTheLogout() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let work = work
        let window = window!
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
        engine.scriptHostedUIRevoke { _, _, _ in
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            return .complete
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        let result = try await signOut(client)

        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertTrue(cancelledCeremony.value)
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// A sign-out that stops the session's passkey registration and whose logout page the user then closes: the
    /// session stays signed in, and the registration's error says what happened without claiming a sign-out.
    ///
    /// - Given: a shared-cookie session whose passkey registration's sheet is up
    /// - When: it is signed out with a window, and the user closes the logout page
    /// - Then:
    ///    - the sign-out throws `.userCancelled`, and the session is still signed in with its record unchanged
    ///    - the registration throws `passkeyRegistrationEnded()`: "cancelled by a sign-out, purge or deletion of
    ///      this session", "if the session is still signed in, register the passkey again"
    func testAClosedLogoutPageLeavesTheStoppedRegistrationsErrorTrue() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }
        engine.scriptHostedUIRevoke { _, _, _ in throw AuthClientError.userCancelled("closed", "retry") }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        let signOutError = await authClientError { try await signOut(client) }
        let associateError = await authClientError { try await associate.value(within: 10) }

        XCTAssertEqual(signOutError?.kind, .userCancelled)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(associateError?.kind, .invalidState)
        XCTAssertEqual(associateError?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertEqual(
            associateError?.errorDescription,
            "The passkey registration was cancelled by a sign-out, purge or deletion of this session."
        )
        XCTAssertEqual(
            associateError?.recoverySuggestion,
            "If the session is still signed in, register the passkey again; otherwise sign in first."
        )
    }

    /// The logout page's wait for the session's own passkey sheet is bounded: a sheet that never closes is the
    /// busy row, and the sign-out still completes.
    ///
    /// - Given: a shared-cookie session whose passkey registration's sheet is up and will not close even when
    ///   cancelled, and a sheet lock whose waits time out at once (its injected sleep)
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.partial` with `hostedUIError` `.browserBusy(holder: work)`: the page was skipped, the
    ///      engine was told `.skip`, and the session is signed out
    ///    - once the sheet finally closes, the lock is free
    func testALogoutPageWhosePasskeySheetNeverClosesIsSkippedAsBusy() async throws {
        harness.sheetLock = SystemSheetLock(sleep: { _ in })
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        let up = Gate(isOpen: true)
        let stuck = Gate()
        engine.scriptCeremonyBody { _ in
            await up.pass()
            // Ignores its cancellation: the sheet that never closes.
            await stuck.pass()
            return Data()
        }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await up.arrivals(1)
        let result = try await withinTime(10, "the sign-out") {
            try await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions())
        }

        XCTAssertEqual(hostedUIError(result)?.kind, .browserBusy(holder: work))
        XCTAssertEqual(plans(engine), ["skip"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        await stuck.open()
        _ = await authClientError { try await associate.value(within: 10) }
        let lock = harness.sheetLock
        await waitUntil("the sheet is free once the passkey sheet closes") { await lock.currentHolder == nil }
    }

    /// The logout page does not wait for another session's sheet, even when it stopped this session's passkey
    /// registration first.
    ///
    /// - Given: a shared-cookie session whose passkey registration is still at `StartWebAuthnRegistration` (no
    ///   sheet yet), another session holding the sheet, and a lock whose waits would fail the test if they
    ///   started a timer
    /// - When: the first session is signed out with a window
    /// - Then:
    ///    - the page is skipped at once: `.partial` with `hostedUIError` `.browserBusy(holder: home)`, nothing
    ///      queued behind the other session, and the session is signed out
    ///    - the stopped registration reports `passkeyRegistrationEnded()` and never shows its sheet
    func testAStoppedRegistrationDoesNotMakeThePageWaitForAnotherSessionsSheet() async throws {
        harness.sheetLock = SystemSheetLock(sleep: { _ in XCTFail("the logout page queued behind another session") })
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        let lock = harness.sheetLock
        let home = home
        let otherHolds = Gate(isOpen: true)
        let otherRelease = Gate()
        let other = Task {
            try await lock.withLease(for: home, policy: .fail) { _ in
                await otherHolds.pass()
                await otherRelease.pass()
            }
        }
        try await otherHolds.arrivals(1)
        let start = Gate()
        engine.scriptPhase5(.associateWebAuthnCredential) { _ in
            await start.pass()
            return ()
        }
        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await start.arrivals(1)

        let result = try await withinTime(10, "the sign-out") {
            try await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions())
        }

        XCTAssertEqual(hostedUIError(result)?.kind, .browserBusy(holder: home))
        XCTAssertEqual(plans(engine), ["skip"])
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 0)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        await start.open()
        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
        await otherRelease.open()
        _ = try await other.value(within: 10)
    }

    /// A passkey lease the lock has granted but whose flow has not attached yet is still stopped, so the logout
    /// page shows (`sheetLock.cancel(for:)` after stopping the registration).
    ///
    /// - Given: a shared-cookie session whose passkey registration's lease is held at the lock's `afterAcquire`
    ///   seam, before its flow attaches (so the flow's own cancel cannot reach the lock)
    /// - When: the session is signed out with a window, and the seam is then let go
    /// - Then:
    ///    - the sign-out queues for the sheet, then presents the logout page: `.complete`, the engine told
    ///      `.present`, the session signed out
    ///    - the registration never shows its sheet, and reports `passkeyRegistrationEnded()`
    func testALeaseNotYetAttachedIsStoppedSoThePageShows() async throws {
        let seamHeld = Gate(isOpen: true)
        let seamRelease = Gate()
        let firstGrant = TestBox(true)
        harness.sheetLock = SystemSheetLock(afterAcquire: { _ in
            let isFirst = firstGrant.with { value -> Bool in
                defer { value = false }
                return value
            }
            guard isFirst else {
                return
            }
            await seamHeld.pass()
            await seamRelease.pass()
        })
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        let lock = harness.sheetLock
        engine.scriptHostedUIRevoke { _, _, _ in .complete }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await seamHeld.arrivals(1)
        let signOut = Task { try await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions()) }
        await waitUntil("the sign-out queues behind the stopped lease") { await lock.waiterCount == 1 }
        await seamRelease.open()

        let result = try await signOut.value(within: 10)
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
    }

    /// - Given: a shared-cookie session, and another session holding the sheet with its hosted-UI sign-in
    /// - When: the first is signed out with a window
    /// - Then:
    ///    - the engine skips the hosted UI; the result is `.partial` with `hostedUIError` `browserBusy` naming the
    ///      holder; the session is signed out
    func testABusySheetSkipsTheLogoutAndReportsIt() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let homeClient = try client(home)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: home)).showWebUISignIns(in: browser)
        let window = window!
        let homeSignIn = Task { try await homeClient.signInWithWebUI(presentationAnchor: window) }
        await browser.shown.waitForArrivals(1)

        let result = try await signOut(client)

        XCTAssertEqual(plans(engine), ["skip"])
        XCTAssertEqual(hostedUIError(result)?.kind, .browserBusy(holder: home))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
        browser.finishWithDefault()
        _ = try await homeSignIn.value
    }

    /// - Given: a shared-cookie session
    /// - When: it is signed out without a window (`signOut(options:)`)
    /// - Then:
    ///    - the engine skips the hosted UI; the result is `.partial` with `hostedUIError`
    ///      `.validation(field: "presentationAnchor")`, whose suggestion names the anchored sign-out
    func testASignOutWithoutAWindowSkipsTheLogoutAndReportsIt() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = try await client.signOut()

        XCTAssertEqual(plans(engine), ["skip"])
        let error = try XCTUnwrap(hostedUIError(result))
        XCTAssertEqual(error.kind, .validation(field: "presentationAnchor"))
        XCTAssertTrue(error.recoverySuggestion.contains("signOut(presentationAnchor:options:)"))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session (an adopted plugin record) under a configuration with no hosted UI
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the engine skips the hosted UI; the result is `.partial` with `hostedUIError` `.configuration`
    func testAConfigurationWithoutAHostedUISkipsTheLogoutAndReportsIt() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work, configuration: ClientFixtures.configuration)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = try await signOut(client)

        XCTAssertEqual(plans(engine), ["skip"])
        XCTAssertEqual(hostedUIError(result)?.kind, .configuration)
    }

    /// - Given: a shared-cookie session whose `.present` sign-out failed in the browser, so the engine reran it
    ///   with the step skipped and reports the failure
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.partial` with that `hostedUIError`, and the session is signed out
    func testABrowserFailureIsReportedInThePartialResult() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptHostedUIRevoke { _, _, _ in
            EngineSignOutOutcome(hostedUIError: .service(.errorLoadingUI, "could not start", "retry"))
        }

        let result = try await signOut(client)

        XCTAssertEqual(hostedUIError(result)?.kind, .service(.errorLoadingUI))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session
    /// - When: the user closes the logout page
    /// - Then:
    ///    - the sign-out throws `.userCancelled` before clearing anything: the session is still signed in, one
    ///      revoke was attempted, and no `.signedOut` is sent
    func testClosingTheLogoutPageKeepsTheSessionSignedIn() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptHostedUIRevoke { _, _, _ in throw AuthClientError.userCancelled("closed", "retry") }
        let events = StreamRecorder(client.listenToAuthEvents())

        let error = await authClientError { try await signOut(client) }

        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(engine.revokeCalls.count, 1)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(events.received, [])
    }

    /// The #3956 exception
    ///
    /// - Given: a shared-cookie session whose refresh token is known to be dead
    /// - When: the user closes the logout page
    /// - Then:
    ///    - the sign-out reruns with the hosted UI skipped and signs out; the result is `.partial` with
    ///      `hostedUIError` `.userCancelled`
    func testClosingTheLogoutPageOfAnExpiredSessionStillSignsOut() async throws {
        var payload = HostedUIFixtures.hostedUIPayload()
        payload.stale = true
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = try await client.fetchAuthSession()
        engine.scriptHostedUIRevoke { _, _, plan in
            if case .present = plan {
                throw AuthClientError.userCancelled("closed", "retry")
            }
            return .complete
        }

        let result = try await signOut(client)

        XCTAssertEqual(plans(engine), ["present", "skip"])
        XCTAssertEqual(hostedUIError(result)?.kind, .userCancelled)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// Retries never present
    ///
    /// - Given: a shared-cookie session whose credentials another writer refreshes during the first revoke
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the first attempt presents and the retry skips the hosted UI; the session is signed out
    func testOnlyTheFirstAttemptPresents() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload(version: 1))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let store = harness.store()
        let work = work
        let refreshed = Flag()
        engine.scriptHostedUIRevoke { _, _, _ in
            if !refreshed.isRaised, case .record(let envelope) = try store.read(work) {
                refreshed.raise()
                try store.write(HostedUIFixtures.hostedUIPayload(version: 2).record(), for: work, expecting: envelope.generation)
            }
            return .complete
        }

        let result = try await signOut(client)

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present", "skip"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// A retry cancelled after an earlier attempt revoked
    ///
    /// - Given: a shared-cookie session whose credentials another writer refreshes during the first revoke, which
    ///   completes; the retry for the refreshed credentials then throws `CancellationError`, as a revoke in a
    ///   cancelled caller's task does
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the record is cleared, never kept with revoked tokens; the cancelled retry is reported as the revoke's
    ///      failure in `.partial`
    func testARetryCancelledAfterARevokeStillClears() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload(version: 1))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let store = harness.store()
        let work = work
        let refreshed = Flag()
        engine.scriptHostedUIRevoke { _, _, _ in
            guard !refreshed.isRaised else {
                throw CancellationError()
            }
            if case .record(let envelope) = try store.read(work) {
                refreshed.raise()
                try store.write(HostedUIFixtures.hostedUIPayload(version: 2).record(), for: work, expecting: envelope.generation)
            }
            return .complete
        }

        let result = try await signOut(client)

        guard case .partial(let partial) = result else {
            return XCTFail("expected .partial, got \(result)")
        }
        XCTAssertNotNil(partial.revokeError)
        XCTAssertEqual(plans(engine), ["present", "skip"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// Starts an anchored sign-out whose engine call is held until `closed` opens, then ends as `end` says,
    /// seeing whether an interrupt cancelled it; interrupts it with `cancelWebUISignIn()`; and returns the task.
    private func interruptedSignOut(
        _ client: AmplifyCognitoClient,
        _ engine: FakeSessionEngine,
        end: @escaping @Sendable (_ interrupted: Bool) throws -> EngineSignOutOutcome
    ) async -> Task<AuthClientSignOutResult, Error> {
        let opened = Gate(isOpen: true)
        let closed = Gate()
        engine.scriptHostedUIRevoke { _, _, _ in
            await opened.pass()
            await closed.pass()
            return try end(Task.isCancelled)
        }
        let window = window!
        let signOut = Task { try await client.signOut(presentationAnchor: window) }
        await opened.waitForArrivals(1)
        await client.cancelWebUISignIn()
        await closed.open()
        return signOut
    }

    /// An interrupt that dismissed the page
    ///
    /// - Given: a shared-cookie session whose logout page is open
    /// - When: `cancelWebUISignIn()` interrupts the lease, and the sign-out then ends with the page closed
    /// - Then:
    ///    - the sign-out throws `.userCancelled` once it has ended, and the session stays signed in
    func testAnInterruptThatClosesTheLogoutPageKeepsTheSessionSignedIn() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let signOut = await interruptedSignOut(client, engine) { interrupted in
            XCTAssertTrue(interrupted)
            throw AuthClientError.userCancelled("closed", "retry")
        }

        let error = await authClientError { try await signOut.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
        let lock = harness.sheetLock
        await waitUntil("the sheet is free") { await lock.currentHolder == nil }
    }

    /// An interrupt after the page had done its work
    ///
    /// - Given: a shared-cookie session whose sign-out is past its logout page, revoking
    /// - When: `cancelWebUISignIn()` interrupts the lease, and the revoke then completes
    /// - Then:
    ///    - the sign-out reports what it did, `.complete`, and the session is signed out
    func testAnInterruptAfterTheLogoutPageSignsOut() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let signOut = await interruptedSignOut(client, engine) { _ in .complete }

        let result = try await signOut.value
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session whose sign-out is past its logout page
    /// - When: `cancelWebUISignIn()` interrupts the lease, and the sign-out then fails at Cognito
    /// - Then:
    ///    - the session is signed out on this device, and the failure is reported as the revoke's
    func testAnInterruptedSignOutThatFailsIsReportedAndSignsOut() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let signOut = await interruptedSignOut(client, engine) { _ in
            throw AuthClientError.service(nil, "revoke failed", "retry")
        }

        let result = try await signOut.value
        guard case .partial(let partial) = result else {
            return XCTFail("expected .partial, got \(result)")
        }
        XCTAssertEqual(partial.revokeError?.errorDescription, "revoke failed")
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    // MARK: The caller's cancellation

    /// Starts an anchored sign-out whose engine call is held, cancels the calling task there, lets the call end
    /// as `end` says, and returns the sign-out's result.
    private func callerCancelledSignOut(
        _ client: AmplifyCognitoClient,
        _ engine: FakeSessionEngine,
        end: @escaping @Sendable (_ interrupted: Bool) throws -> EngineSignOutOutcome
    ) async -> Result<AuthClientSignOutResult, Error> {
        let opened = Gate(isOpen: true)
        let closed = Gate()
        engine.scriptHostedUIRevoke { _, _, _ in
            await opened.pass()
            await closed.pass()
            return try end(Task.isCancelled)
        }
        let window = window!
        let signOut = Task { try await client.signOut(presentationAnchor: window) }
        await opened.waitForArrivals(1)
        signOut.cancel()
        await closed.open()
        return await signOut.result
    }

    /// - Given: a shared-cookie session whose sign-out is past its logout page, revoking
    /// - When: the calling task is cancelled, and the revoke then completes
    /// - Then:
    ///    - the sign-out returns what it did, `.complete`, and the session is signed out on this device
    func testACallerCancelledAfterTheLogoutPageStillSignsOut() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = await callerCancelledSignOut(client, engine) { _ in .complete }

        XCTAssertEqual(try result.get(), .complete)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session whose logout page is open
    /// - When: the calling task is cancelled, which closes the page
    /// - Then:
    ///    - the sign-out throws `CancellationError`, and the session stays signed in
    func testACallerCancelledOnTheLogoutPageKeepsTheSession() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = await callerCancelledSignOut(client, engine) { interrupted in
            XCTAssertTrue(interrupted)
            throw AuthClientError.userCancelled("closed", "retry")
        }

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertTrue(error is CancellationError, "got \(error)")
        }
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    // MARK: An interrupt before the lease body starts (verification blocker)

    /// Where the lock is held when the sign-out's lease is interrupted, before its body runs.
    private enum EarlyWindow {
        /// `cancel(for:)` between the grant and the flow's registration.
        case cancelBeforeAttach
        /// `reset()` in the same window.
        case resetBeforeAttach
        /// `cancel(for:)` after the registration, before the body starts (the lock skips the body).
        case cancelBeforeStart
        /// `cancel(for:)` once the flow has started, before the body's first step: the body runs, finds itself
        /// abandoned, and never calls the engine.
        case cancelBeforeBodyBegins
    }

    /// Interrupts an anchored sign-out of a shared-cookie session in `window`, then checks that it answers the
    /// closed-page row at once, and that a later sign-out on the same client is not blocked behind it.
    private func assertAnEarlyInterruptAnswers(_ window: EarlyWindow, file: StaticString = #filePath, line: UInt = #line) async throws {
        let held = Gate()
        switch window {
        case .cancelBeforeAttach, .resetBeforeAttach:
            harness.sheetLock = SystemSheetLock(afterAcquire: { _ in await held.pass() })
        case .cancelBeforeStart:
            harness.sheetLock = SystemSheetLock(afterAttach: { _ in await held.pass() })
        case .cancelBeforeBodyBegins:
            harness.sheetLock = SystemSheetLock(beforeBody: { _ in await held.pass() })
        }
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let anchor = self.window!
        let signOut = Task { try await client.signOut(presentationAnchor: anchor) }
        await held.waitForArrivals(1)

        switch window {
        case .cancelBeforeAttach, .cancelBeforeStart, .cancelBeforeBodyBegins:
            await client.cancelWebUISignIn()
        case .resetBeforeAttach:
            await harness.sheetLock.reset()
        }
        let answered = expectation(description: "the interrupted sign-out answers")
        let outcome = ResultBox<AuthClientSignOutResult>()
        Task {
            outcome.set(await signOut.result)
            answered.fulfill()
        }
        if window == .cancelBeforeBodyBegins {
            // The flow is held inside its task: the sign-out answers first, abandoning the body, which then runs.
            await fulfillment(of: [answered], timeout: 10)
            await held.open()
        } else {
            await held.open()
            await fulfillment(of: [answered], timeout: 10)
        }
        XCTAssertThrowsError(try outcome.value?.get(), file: file, line: line) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .userCancelled, file: file, line: line)
        }
        XCTAssertEqual(engine.revokeCalls.count, 0, "the body never ran", file: file, line: line)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false, file: file, line: line)

        let followUp = expectation(description: "a later sign-out on the same client returns")
        let later = ResultBox<AuthClientSignOutResult>()
        Task {
            do {
                later.set(.success(try await client.signOut()))
            } catch {
                later.set(.failure(error))
            }
            followUp.fulfill()
        }
        await fulfillment(of: [followUp], timeout: 10)
        XCTAssertNoThrow(try later.value?.get(), file: file, line: line)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true, file: file, line: line)
    }

    /// - Given: an anchored sign-out whose lease has been granted but not yet registered its flow
    /// - When: `cancelWebUISignIn()` lands there
    /// - Then:
    ///    - the sign-out answers `.userCancelled` at once, nothing ran, the session stays signed in, and a later
    ///      `signOut()` on the same client returns
    func testACancelBetweenGrantAndAttachAnswersAtOnce() async throws {
        try await assertAnEarlyInterruptAnswers(.cancelBeforeAttach)
    }

    /// - Given: an anchored sign-out whose lease has been granted but not yet registered its flow
    /// - When: the sheet is reset there
    /// - Then:
    ///    - the same
    func testAResetBetweenGrantAndAttachAnswersAtOnce() async throws {
        try await assertAnEarlyInterruptAnswers(.resetBeforeAttach)
    }

    /// - Given: an anchored sign-out whose flow has registered but whose body has not started
    /// - When: `cancelWebUISignIn()` lands there, so the lock skips the body
    /// - Then:
    ///    - the same
    func testACancelBetweenAttachAndStartAnswersAtOnce() async throws {
        try await assertAnEarlyInterruptAnswers(.cancelBeforeStart)
    }

    /// - Given: an anchored sign-out whose flow has started, held before its body's first step
    /// - When: `cancelWebUISignIn()` lands there, and the body then runs
    /// - Then:
    ///    - the sign-out answers `.userCancelled` at once; the body finds itself abandoned and never calls the
    ///      engine; a later `signOut()` returns
    func testACancelBeforeTheBodyBeginsAnswersAtOnce() async throws {
        try await assertAnEarlyInterruptAnswers(.cancelBeforeBodyBegins)
    }

    // MARK: Without a live session

    /// - Given: a saved shared-cookie session with no live client
    /// - When: it is signed out through `signOutStoredSession`
    /// - Then:
    ///    - it is revoked and signed out, and `.partial` reports the no-window `hostedUIError`
    func testSignOutStoredSessionReportsTheCookieLeftBehind() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())

        let result = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: work,
            configuration: HostedUIFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(harness.revoker.revokeCalls.count, 1)
        XCTAssertEqual(hostedUIError(result)?.kind, .validation(field: "presentationAnchor"))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a saved password session with no live client
    /// - When: it is signed out through `signOutStoredSession`
    /// - Then:
    ///    - the result is `.complete`
    func testSignOutStoredSessionOfAPasswordSessionIsComplete() async throws {
        try harness.signIn(work, .signedIn("alice"))

        let result = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: work,
            configuration: HostedUIFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(result, .complete)
    }
}
#endif

/// `EngineSignOutOutcome.hostedUIError` in `merge`, `isComplete`, `==`, the partial result, and a contended
/// sign-out's thrown error.
final class SignOutOutcomeHostedUITests: XCTestCase {

    private let busy = AuthClientError.browserBusy(holder: .default, "busy", "wait")
    private let revoke = AuthClientError.service(nil, "revoke failed", "retry")

    /// - Given: an outcome with only a hosted-UI failure
    /// - When: it is read
    /// - Then:
    ///    - it is not complete, and its partial result carries the failure alone
    func testAHostedUIFailureAloneIsPartial() {
        let outcome = EngineSignOutOutcome(hostedUIError: busy)

        XCTAssertFalse(outcome.isComplete)
        XCTAssertEqual(outcome.partial, AuthClientPartialSignOut(revokeError: nil, hostedUIError: busy))
        XCTAssertEqual(outcome.partial?.hostedUIError?.kind, .browserBusy(holder: .default))
    }

    /// - Given: two outcomes, each with a hosted-UI failure
    /// - When: they are merged
    /// - Then:
    ///    - the first hosted-UI failure is kept, beside the other kinds
    func testMergeKeepsTheFirstHostedUIFailure() {
        var outcome = EngineSignOutOutcome(hostedUIError: busy)
        outcome.merge(EngineSignOutOutcome(revokeError: revoke, hostedUIError: .userCancelled("closed", "retry")))

        XCTAssertEqual(outcome, EngineSignOutOutcome(revokeError: revoke, hostedUIError: busy))
    }

    /// - Given: outcomes that differ only in their hosted-UI failure
    /// - When: they are compared
    /// - Then:
    ///    - they are unequal, and so are their partial results
    func testEqualityComparesTheHostedUIFailure() {
        XCTAssertNotEqual(EngineSignOutOutcome(hostedUIError: busy), EngineSignOutOutcome.complete)
        XCTAssertNotEqual(
            AuthClientPartialSignOut(revokeError: nil, hostedUIError: busy),
            AuthClientPartialSignOut(revokeError: nil)
        )
    }

    /// - Given: a sign-out whose every attempt lost its race, with only a hosted-UI failure
    /// - When: its result is read
    /// - Then:
    ///    - it throws `storageUnavailable(.interrupted)` carrying the hosted-UI failure underneath
    func testAContendedSignOutCarriesTheHostedUIFailure() {
        let outcome = SessionSignOut.Outcome.contended(server: EngineSignOutOutcome(hostedUIError: busy))

        XCTAssertThrowsError(try outcome.result()) { error in
            let error = error as? AuthClientError
            XCTAssertEqual(error?.storageUnavailableReason, .interrupted)
            XCTAssertEqual((error?.underlyingError as? AuthClientError)?.kind, .browserBusy(holder: .default))
        }
    }
}

/// A value set from another task, read after an expectation.
final class ResultBox<Value: Sendable>: @unchecked Sendable {
    // `@unchecked Sendable`: only touched while holding `lock`.
    private let lock = NSLock()
    private var stored: Result<Value, Error>?

    var value: Result<Value, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }

    func set(_ result: Result<Value, Error>) {
        lock.lock()
        stored = result
        lock.unlock()
    }
}
