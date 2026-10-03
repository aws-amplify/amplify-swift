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
    ) async -> AuthClientSignOutResult {
        let window = window!
        return await client.signOut(presentationAnchor: window, options: options)
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
        result.partialErrors?.hostedUIError
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

            let result = await signOut(client)

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

        let result = await signOut(client, options: AuthClientSignOutOptions(globalSignOut: true))

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
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
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
        let result = await signOut(client)

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
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
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
        let signOutError = await failedSignOutError(signOut(client))
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
    /// busy row, and the sign-out still answers (`.failed`, as the plugin's).
    ///
    /// - Given: a shared-cookie session whose passkey registration's sheet is up and will not close even when
    ///   cancelled, and a sheet lock whose waits time out at once (its injected sleep)
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.browserBusy(holder: work))`: the page could not be shown, the engine was never
    ///      called, and the session is still signed in
    ///    - once the sheet finally closes, the lock is free
    func testALogoutPageWhosePasskeySheetNeverClosesIsFailedAsBusy() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
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
            await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions())
        }

        XCTAssertEqual(failedSignOutError(result)?.kind, .browserBusy(holder: work))
        XCTAssertEqual(failedSignOutError(result)?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
        await stuck.open()
        _ = await authClientError { try await associate.value(within: 10) }
        let lock = harness.sheetLock
        await waitUntil("the sheet is free once the passkey sheet closes") { await lock.currentHolder == nil }
    }

    /// Another session's sheet refuses the logout page before anything is stopped, so a refused sign-out leaves
    /// this session's passkey registration alone.
    ///
    /// - Given: a shared-cookie session whose passkey registration is still at `StartWebAuthnRegistration` (no
    ///   sheet yet), another session holding the sheet, and a lock whose waits would fail the test if they
    ///   started a timer
    /// - When:
    ///    - the first session is signed out with a window
    ///    - then the other session lets the sheet go, and the registration's `StartWebAuthnRegistration` answers
    /// - Then:
    ///    - the sign-out answers at once: `.failed(.browserBusy(holder: home))` with the sign-out's suggestion,
    ///      nothing queued behind the other session, nothing revoked, and the session still signed in with its
    ///      record unchanged
    ///    - the registration is untouched: it goes on to show its sheet and succeeds
    func testABusySheetRefusalLeavesTheSessionsPasskeyRegistrationAlone() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        harness.sheetLock = SystemSheetLock(sleep: { _ in XCTFail("the logout page queued behind another session") })
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
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
            await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions())
        }

        XCTAssertEqual(failedSignOutError(result)?.kind, .browserBusy(holder: home))
        XCTAssertEqual(failedSignOutError(result)?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(engine.revokeCalls, [])
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 0)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        await otherRelease.open()
        _ = try await other.value(within: 10)
        await start.open()
        do {
            try await associate.value(within: 10)
        } catch {
            // Names the error, so a regression reads `passkeyRegistrationEnded()` rather than a bare throw.
            XCTFail("the registration failed: \((error as? AuthClientError)?.errorDescription ?? "\(error)")")
        }
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 1)
    }

    /// Taking the sheet is the sign-out's busy check, so another session that takes the sheet at the last moment,
    /// just before the sign-out asks for it, still leaves this session's passkey registration alone.
    ///
    /// - Given: a shared-cookie session whose passkey registration is still at `StartWebAuthnRegistration` (no
    ///   sheet yet), a free sheet, and a lock that holds the session's first call for the sheet at `beforeAcquire`
    /// - When:
    ///    - the session is signed out with a window, and another session takes the sheet while the sign-out is
    ///      held there, just before it asks
    ///    - then the other session lets the sheet go, and the registration's `StartWebAuthnRegistration` answers
    /// - Then:
    ///    - the sign-out is `.failed(.browserBusy(holder: home))` with the sign-out's suggestion: nothing queued,
    ///      nothing revoked, and the session still signed in with its record unchanged
    ///    - the registration was never stopped: it goes on to show its sheet and succeeds
    func testASheetTakenJustBeforeTheSignOutAsksLeavesTheRegistrationAlone() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        let work = work
        let home = home
        let signOutAsks = Gate()
        let firstCall = TestBox(true)
        harness.sheetLock = SystemSheetLock(
            sleep: { _ in XCTFail("the logout page queued behind another session") },
            beforeAcquire: { session in
                guard session == work, firstCall.with({ value -> Bool in
                    defer { value = false }
                    return value
                }) else {
                    return
                }
                await signOutAsks.pass()
            }
        )
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        let lock = harness.sheetLock
        let start = Gate()
        engine.scriptPhase5(.associateWebAuthnCredential) { _ in
            await start.pass()
            return ()
        }
        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await start.arrivals(1)

        let signOut = Task { await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions()) }
        try await signOutAsks.arrivals(1)
        let otherHolds = Gate(isOpen: true)
        let otherRelease = Gate()
        let other = Task {
            try await lock.withLease(for: home, policy: .fail) { _ in
                await otherHolds.pass()
                await otherRelease.pass()
            }
        }
        try await otherHolds.arrivals(1)
        await signOutAsks.open()
        let result = try await signOut.value(within: 10)

        XCTAssertEqual(failedSignOutError(result)?.kind, .browserBusy(holder: home))
        XCTAssertEqual(failedSignOutError(result)?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(engine.revokeCalls, [])
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 0)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        await otherRelease.open()
        _ = try await other.value(within: 10)
        await start.open()
        do {
            try await associate.value(within: 10)
        } catch {
            // Names the error, so a regression reads `passkeyRegistrationEnded()` rather than a bare throw.
            XCTFail("the registration failed: \((error as? AuthClientError)?.errorDescription ?? "\(error)")")
        }
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 1)
    }

    /// A lock whose `beforeRelease` holds the first release of a `work` lease, the passkey sheet's, at `held` until
    /// `go` opens; and whose waits time out only when the test is long over.
    private func lockHoldingThePasskeySheetsRelease(held: Gate, go: Gate) -> SystemSheetLock {
        let work = work
        let first = TestBox(true)
        return SystemSheetLock(
            sleep: { _ in try await Task.sleep(nanoseconds: 3_600_000_000_000) },
            beforeRelease: { lease in
                guard lease.holder == work, first.with({ value -> Bool in
                    defer { value = false }
                    return value
                }) else {
                    return
                }
                await held.pass()
                await go.pass()
            }
        )
    }

    /// The page's lease is refused while the session's own passkey sheet is up: the sign-out stops the
    /// registration, waits for that sheet to close, and only then shows the page.
    ///
    /// - Given: a shared-cookie session whose passkey registration's sheet is up, and a lock that holds that
    ///   sheet's release at `beforeRelease`, once the sheet has closed
    /// - When: the session is signed out with a window, and the release is then let go
    /// - Then:
    ///    - the registration is stopped and reports `passkeyRegistrationEnded()`, while the closing sheet is still
    ///      the session's; the sign-out queues for it, without calling the engine
    ///    - once the sheet is released, the page is presented under the session's lease: `.complete`, and the
    ///      session is signed out
    func testASignOutWaitsForItsOwnClosingPasskeySheetThenShowsThePage() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        let releaseHeld = Gate(isOpen: true)
        let releaseGo = Gate()
        harness.sheetLock = lockHoldingThePasskeySheetsRelease(held: releaseHeld, go: releaseGo)
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let work = work
        let window = window!
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }
        engine.scriptHostedUIRevoke { _, _, _ in
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            return .complete
        }
        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()

        let signOut = Task { await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions()) }
        try await releaseHeld.arrivals(1)
        await waitUntil("the sign-out queues behind its own closing sheet") { await lock.waiterCount == 1 }

        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        let holderWhileClosing = await lock.currentHolder
        XCTAssertEqual(holderWhileClosing, work)
        XCTAssertEqual(plans(engine), [])
        await releaseGo.open()
        let result = try await signOut.value(within: 10)
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// The page waits only for the session's own closing passkey sheet: when the lock passes from it to another
    /// session queued behind it, the sign-out is refused at once, not after `passkeySheetClosingTimeout`.
    ///
    /// - Given: a shared-cookie session whose passkey registration's sheet is up, another session queued behind it
    ///   with `.wait`, and a lock that holds the passkey sheet's release at `beforeRelease` and whose waits time out
    ///   only when the test is long over
    /// - When: the session is signed out with a window, so it stops the registration and queues; then the release
    ///   is let go, and the lock passes to the other session
    /// - Then:
    ///    - the sign-out is `.failed(.browserBusy(holder: home))` at once, saying the other session holds the sheet,
    ///      not that a wait timed out, with the sign-out's suggestion; the engine was never called, and the session
    ///      is still signed in
    ///    - the other session holds the sheet, and nothing is left queued
    func testAnOwnSheetThatPassesToAnotherSessionAsItClosesIsRefusedAtOnce() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        let releaseHeld = Gate(isOpen: true)
        let releaseGo = Gate()
        harness.sheetLock = lockHoldingThePasskeySheetsRelease(held: releaseHeld, go: releaseGo)
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let work = work
        let home = home
        let window = window!
        let held = HeldSheet()
        engine.scriptCeremonyBody { _ in
            try await held.answer()
            return Data()
        }
        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        let otherHolds = Gate(isOpen: true)
        let otherRelease = Gate()
        let other = Task {
            try await lock.withLease(for: home, policy: .wait(timeout: 60)) { _ in
                await otherHolds.pass()
                await otherRelease.pass()
            }
        }
        await waitUntil("the other session queues behind the passkey sheet") { await lock.waiterCount == 1 }

        let signOut = Task { await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions()) }
        try await releaseHeld.arrivals(1)
        await waitUntil("the sign-out queues behind its own closing sheet") { await lock.waiterCount == 2 }
        await releaseGo.open()
        let result = try await signOut.value(within: 10)

        let refusal = failedSignOutError(result)
        XCTAssertEqual(refusal?.kind, .browserBusy(holder: home))
        XCTAssertEqual(
            refusal?.errorDescription,
            AuthClientError.browserBusy(heldBy: home, requestedBy: work, reason: .heldByAnotherSession).errorDescription
        )
        XCTAssertEqual(refusal?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
        try await otherHolds.arrivals(1)
        let holder = await lock.currentHolder
        XCTAssertEqual(holder, home)
        let waiters = await lock.waiterCount
        XCTAssertEqual(waiters, 0)
        let error = await authClientError { try await associate.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        await otherRelease.open()
        _ = try await other.value(within: 10)
    }

    /// A sheet this session held at the first ask, with no passkey registration to stop by the time the sign-out
    /// looks (one that ended and unregistered in between), is asked for once more, so a sheet that is free by then
    /// shows the page rather than a busy refusal naming the session itself.
    ///
    /// - Given: a shared-cookie session that holds the sheet itself with no registration in flight, and a lock
    ///   whose `beforeAcquire` lets that hold go just before the session's next ask after the sign-out's first
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the first ask is refused (the session holds the sheet) and nothing is stopped; the second ask, with
    ///      `.fail`, finds the sheet free
    ///    - the page is presented under the session's lease: `.complete`, and the session is signed out
    func testASheetThisSessionFreesWithNothingToStopIsAskedForAgain() async throws {
        let work = work
        let calls = TestBox(0)
        let release = Gate()
        let hold = ResultBox<Task<Void, Error>>()
        harness.sheetLock = SystemSheetLock(beforeAcquire: { session in
            guard session == work else {
                return
            }
            let call = calls.with { value -> Int in
                value += 1
                return value
            }
            // 1 is the hold below, 2 the sign-out's first ask, 3 its second.
            guard call == 3 else {
                return
            }
            await release.open()
            _ = try? await hold.value?.get().value
        })
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let window = window!
        engine.scriptHostedUIRevoke { _, _, _ in
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            return .complete
        }
        let holds = Gate(isOpen: true)
        hold.set(.success(Task {
            try await lock.withLease(for: work, policy: .fail) { _ in
                await holds.pass()
                await release.pass()
            }
        }))
        try await holds.arrivals(1)

        let result = try await withinTime(10, "the sign-out") {
            await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions())
        }

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        XCTAssertEqual(calls.value, 3)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// With the sheet free, the sign-out takes it first and only then stops the session's passkey registration,
    /// inside its lease and before the engine's sign-out.
    ///
    /// - Given: a shared-cookie session whose passkey registration is still at `StartWebAuthnRegistration` (no
    ///   sheet yet), and a free sheet
    /// - When: the session is signed out with a window; inside the engine's sign-out the registration's
    ///   `StartWebAuthnRegistration` answers
    /// - Then:
    ///    - the engine is called while the session holds the sheet, and by then the registration has been stopped:
    ///      it reports `passkeyRegistrationEnded()` without showing its sheet, before the engine's sign-out returns
    ///    - the result is `.complete`, and the session is signed out
    func testATakenSheetStopsTheRegistrationInsideTheLeaseBeforeTheRevoke() async throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let work = work
        let window = window!
        let start = Gate()
        engine.scriptPhase5(.associateWebAuthnCredential) { _ in
            await start.pass()
            return ()
        }
        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await start.arrivals(1)
        let duringRevoke = ResultBox<AuthClientError?>()
        engine.scriptHostedUIRevoke { _, _, _ in
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            await start.open()
            let error = await authClientError { try await associate.value(within: 10) }
            duringRevoke.set(.success(error))
            return .complete
        }

        let result = await signOut(client)

        let error = try XCTUnwrap(duringRevoke.value?.get(), "the registration had not ended inside the revoke")
        XCTAssertEqual(error.errorDescription, SessionCore.passkeyRegistrationEnded().errorDescription)
        XCTAssertEqual(engine.ceremonyAnchorCalls.count, 0)
        XCTAssertEqual(result, .complete)
        XCTAssertEqual(plans(engine), ["present"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
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
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn is not available on this OS version")
        }
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
        let signOut = Task { await client.signOut(presentationAnchor: window, options: AuthClientSignOutOptions()) }
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

    /// a page the user asked for that cannot be shown is the plugin's `.failed`.
    ///
    /// - Given: a shared-cookie session, and another session holding the sheet with its hosted-UI sign-in
    /// - When: the first is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.browserBusy)` naming the holder; nothing is revoked, and the session is still
    ///      signed in
    func testABusySheetIsFailedAndStaysSignedIn() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let homeClient = try client(home)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: home)).showWebUISignIns(in: browser)
        let window = window!
        let homeSignIn = Task { try await homeClient.signInWithWebUI(presentationAnchor: window) }
        await browser.shown.waitForArrivals(1)

        let result = await signOut(client)

        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(failedSignOutError(result)?.kind, .browserBusy(holder: home))
        XCTAssertEqual(failedSignOutError(result)?.recoverySuggestion, SessionCore.signOutBrowserBusySuggestion)
        XCTAssertEqual(engine.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
        browser.finishWithDefault()
        _ = try await homeSignIn.value
    }

    /// A sign-out has no `whenBrowserBusy`, so its busy refusal must not suggest one; the sign-in texts keep it.
    ///
    /// - Given: the sheet lock's `browserBusy` for a session held by another, still closing, and timed out
    /// - When: each is made a sign-out's refusal
    /// - Then:
    ///    - the holder and description are kept, and the suggestion is the sign-out's, naming no `whenBrowserBusy`
    ///    - the sign-in errors themselves still suggest `whenBrowserBusy: .wait(timeout:)`
    func testABusySignOutRefusalSuggestsRetryingTheSignOut() {
        for reason in [BrowserBusyReason.heldByAnotherSession, .stillClosing, .timedOut] {
            let signIn = AuthClientError.browserBusy(heldBy: home, requestedBy: work, reason: reason)

            let signOut = SessionCore.signOutBrowserBusy(signIn)

            XCTAssertEqual(signOut.kind, .browserBusy(holder: home), "\(reason)")
            XCTAssertEqual(signOut.errorDescription, signIn.errorDescription, "\(reason)")
            XCTAssertEqual(
                signOut.recoverySuggestion,
                "Retry the sign-out when the other sheet has closed; the session is still signed in.",
                "\(reason)"
            )
            XCTAssertFalse(signOut.recoverySuggestion.contains("whenBrowserBusy"), "\(reason)")
            XCTAssertTrue(signIn.recoverySuggestion.contains("whenBrowserBusy: .wait(timeout:)"), "\(reason)")
        }
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

        let result = await client.signOut()

        XCTAssertEqual(plans(engine), ["skip"])
        let error = try XCTUnwrap(hostedUIError(result))
        XCTAssertEqual(error.kind, .validation(field: "presentationAnchor"))
        XCTAssertTrue(error.recoverySuggestion.contains("signOut(presentationAnchor:options:)"))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// as the plugin, a hosted-UI sign-out with no hosted UI to sign out of fails, and the user stays
    /// signed in.
    ///
    /// - Given: a shared-cookie session (an adopted plugin record) under a configuration with no hosted UI
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.configuration)`; nothing is revoked; the session is still signed in, and no
    ///      `.signedOut` is sent
    func testHostedUISignOutWithNoHostedUIConfigurationIsFailedAndStaysSignedIn() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work, configuration: ClientFixtures.configuration)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = await signOut(client)

        let error = failedSignOutError(result)
        XCTAssertEqual(error?.kind, .configuration)
        XCTAssertEqual(error.map { $0.isEquivalent(to: SessionCore.noHostedUIForSignOut()) }, true)
        XCTAssertEqual(engine.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(events.received, [])
    }

    /// the same for a hosted UI configured with no sign-out redirect URI.
    ///
    /// - Given: a shared-cookie session under a configuration whose `oauth` has no sign-out redirect URI
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed(.configuration)`; nothing is revoked; the session is still signed in
    func testHostedUISignOutWithNoSignOutRedirectURIIsFailedAndStaysSignedIn() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let oauth = try XCTUnwrap(HostedUIFixtures.userPool.oauth)
        let userPool = AuthClientConfiguration.UserPool(
            poolId: HostedUIFixtures.userPool.poolId,
            appClientId: HostedUIFixtures.userPool.appClientId,
            region: HostedUIFixtures.userPool.region,
            oauth: AuthClientConfiguration.OAuth(
                domain: oauth.domain,
                scopes: oauth.scopes,
                redirectSignInURIs: oauth.redirectSignInURIs,
                redirectSignOutURIs: []
            )
        )
        let configuration = ClientFixtures.make(userPool: userPool, identityPool: ClientFixtures.identityPool)
        let client = try client(work, configuration: configuration)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = await signOut(client)

        XCTAssertEqual(failedSignOutError(result)?.kind, .configuration)
        XCTAssertEqual(engine.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// the engine's own check of the hosted UI's configuration (`HostedUIError.pluginConfiguration`, or a
    /// sign-out redirect URI it cannot use) is the same `.failed`.
    ///
    /// - Given: a shared-cookie session whose `.present` sign-out the engine refuses for its configuration
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.failed` with the engine's error; the session is still signed in
    func testAnEngineRefusalOfTheHostedUIConfigurationIsFailedAndStaysSignedIn() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let refused = AuthClientError.configuration("no sign-out redirect URI", "add one")
        engine.scriptHostedUIRevoke { _, _, _ in throw SignOutRefusal(error: refused) }

        let result = await signOut(client)

        XCTAssertEqual(result, .failed(refused))
        XCTAssertEqual(engine.revokeCalls.count, 1)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, payload.data)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// A failure the engine continues past (one that is not a `HostedUIError`, which the plugin also continues past
    /// in `ShowHostedUISignOut`) is still reported beside the revoke. A `HostedUIError` is a refusal instead
    /// (`testAnEngineRefusalOfTheHostedUIConfigurationIsFailedAndStaysSignedIn`, and the live engine's tests).
    ///
    /// - Given: a shared-cookie session whose `.present` sign-out signed out past a failure of the browser step
    /// - When: it is signed out with a window
    /// - Then:
    ///    - the result is `.partial` with that `hostedUIError`, and the session is signed out
    func testABrowserFailureTheEngineContinuedPastIsReportedInThePartialResult() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptHostedUIRevoke { _, _, _ in
            EngineSignOutOutcome(hostedUIError: .service(.errorLoadingUI, "could not start", "retry"))
        }

        let result = await signOut(client)

        XCTAssertEqual(hostedUIError(result)?.kind, .service(.errorLoadingUI))
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session
    /// - When: the user closes the logout page
    /// - Then:
    ///    - the sign-out is `.failed(.userCancelled)` before clearing anything: the session is still signed in,
    ///      one revoke was attempted, and no `.signedOut` is sent
    func testClosingTheLogoutPageKeepsTheSessionSignedIn() async throws {
        let payload = HostedUIFixtures.hostedUIPayload()
        try harness.signIn(work, payload)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptHostedUIRevoke { _, _, _ in throw AuthClientError.userCancelled("closed", "retry") }
        let events = StreamRecorder(client.listenToAuthEvents())

        let error = await failedSignOutError(signOut(client))

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

        let result = await signOut(client)

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
                try store.write(HostedUIFixtures.hostedUIPayload(version: 2).record(), for: work, expecting: envelope.version)
            }
            return .complete
        }

        let result = await signOut(client)

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
                try store.write(HostedUIFixtures.hostedUIPayload(version: 2).record(), for: work, expecting: envelope.version)
            }
            return .complete
        }

        let result = await signOut(client)

        let partial = try XCTUnwrap(result.partialErrors, "expected .partial, got \(result)")
        XCTAssertNotNil(partial.revokeTokenError)
        XCTAssertEqual(plans(engine), ["present", "skip"])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// Starts an anchored sign-out whose engine call is held until `closed` opens, then ends as `end` says,
    /// seeing whether an interrupt cancelled it; interrupts it with `cancelWebUISignIn()`; and returns the task.
    private func interruptedSignOut(
        _ client: AmplifyCognitoClient,
        _ engine: FakeSessionEngine,
        end: @escaping @Sendable (_ interrupted: Bool) throws -> EngineSignOutOutcome
    ) async -> Task<AuthClientSignOutResult, Never> {
        let opened = Gate(isOpen: true)
        let closed = Gate()
        engine.scriptHostedUIRevoke { _, _, _ in
            await opened.pass()
            await closed.pass()
            return try end(Task.isCancelled)
        }
        let window = window!
        let signOut = Task { await client.signOut(presentationAnchor: window) }
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
    ///    - the sign-out is `.failed(.userCancelled)` once it has ended, and the session stays signed in
    func testAnInterruptThatClosesTheLogoutPageKeepsTheSessionSignedIn() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let signOut = await interruptedSignOut(client, engine) { interrupted in
            XCTAssertTrue(interrupted)
            throw AuthClientError.userCancelled("closed", "retry")
        }

        let error = await failedSignOutError(signOut.value)
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

        let result = await signOut.value
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

        let result = await signOut.value
        let partial = try XCTUnwrap(result.partialErrors, "expected .partial, got \(result)")
        XCTAssertEqual(partial.revokeTokenError?.errorDescription, "revoke failed")
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    // MARK: The caller's cancellation

    /// Starts an anchored sign-out whose engine call is held, cancels the calling task there, lets the call end
    /// as `end` says, and returns the sign-out's result.
    private func callerCancelledSignOut(
        _ client: AmplifyCognitoClient,
        _ engine: FakeSessionEngine,
        end: @escaping @Sendable (_ interrupted: Bool) throws -> EngineSignOutOutcome
    ) async -> AuthClientSignOutResult {
        let opened = Gate(isOpen: true)
        let closed = Gate()
        engine.scriptHostedUIRevoke { _, _, _ in
            await opened.pass()
            await closed.pass()
            return try end(Task.isCancelled)
        }
        let window = window!
        let signOut = Task { await client.signOut(presentationAnchor: window) }
        await opened.waitForArrivals(1)
        signOut.cancel()
        await closed.open()
        return await signOut.value
    }

    /// - Given: a shared-cookie session whose sign-out is past its logout page, revoking
    /// - When: the calling task is cancelled, and the revoke then completes
    /// - Then:
    ///    - the sign-out returns what it did, `.complete`, and the session is signed out on this device: once a
    ///      revoke has completed, cancellation never stops the local clear
    func testACallerCancelledAfterTheLogoutPageStillSignsOut() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = await callerCancelledSignOut(client, engine) { _ in .complete }

        XCTAssertEqual(result, .complete)
        XCTAssertTrue(result.signedOutLocally)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, true)
    }

    /// - Given: a shared-cookie session whose logout page is open
    /// - When: the calling task is cancelled, which closes the page
    /// - Then:
    ///    - the sign-out is `.failed(.unknown)`, with an underlying `CancellationError`, and the session
    ///      stays signed in
    func testACallerCancelledOnTheLogoutPageKeepsTheSession() async throws {
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = await callerCancelledSignOut(client, engine) { interrupted in
            XCTAssertTrue(interrupted)
            throw AuthClientError.userCancelled("closed", "retry")
        }

        let error = failedSignOutError(result)
        XCTAssertEqual(error.map { $0.isEquivalent(to: SessionSignOut.cancelledError()) }, true, "got \(result)")
        XCTAssertTrue(error?.underlyingError is CancellationError)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
    }

    /// An interrupt that lands inside the lease body, once it has stopped the passkey registrations and before it
    /// shows the page: the body's cancellation check stops it there, so nothing is shown or revoked.
    ///
    /// - Given: a shared-cookie session, and a sign-out held at the `afterLogoutStop` seam inside its lease body
    /// - When: `cancelWebUISignIn()` interrupts the lease there, and the body is then let go
    /// - Then:
    ///    - the sign-out is `.failed(.userCancelled)`, the closed-page row: the engine was never called, and the
    ///      session is still signed in
    ///    - the sheet is free afterwards
    func testAnInterruptAfterTheRegistrationsAreStoppedShowsNoPage() async throws {
        let held = Gate()
        harness.afterLogoutStop = { _ in await held.pass() }
        try harness.signIn(work, HostedUIFixtures.hostedUIPayload())
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let lock = harness.sheetLock
        let window = window!
        let signOut = Task { await client.signOut(presentationAnchor: window) }
        await held.waitForArrivals(1)

        await client.cancelWebUISignIn()
        await held.open()
        let result = try await signOut.value(within: 10)

        XCTAssertEqual(failedSignOutError(result)?.kind, .userCancelled, "got \(result)")
        XCTAssertEqual(plans(engine), [])
        XCTAssertEqual(engine.revokeCalls, [])
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false)
        await waitUntil("the sheet is free") { await lock.currentHolder == nil }
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
        let signOut = Task { await client.signOut(presentationAnchor: anchor) }
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
            outcome.set(.success(await signOut.value))
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
        let result = try XCTUnwrap(outcome.value?.get(), file: file, line: line)
        XCTAssertEqual(failedSignOutError(result, file: file, line: line)?.kind, .userCancelled, file: file, line: line)
        XCTAssertEqual(engine.revokeCalls.count, 0, "the body never ran", file: file, line: line)
        XCTAssertEqual(try harness.storedRecord(work)?.isSignedOut, false, file: file, line: line)

        let followUp = expectation(description: "a later sign-out on the same client returns")
        let later = ResultBox<AuthClientSignOutResult>()
        Task {
            later.set(.success(await client.signOut()))
            followUp.fulfill()
        }
        await fulfillment(of: [followUp], timeout: 10)
        XCTAssertEqual(try later.value?.get().signedOutLocally, true, file: file, line: line)
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

        let result = await AmplifyCognitoClient.signOutStoredSession(
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

        let result = await AmplifyCognitoClient.signOutStoredSession(
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
        XCTAssertEqual(outcome.signedOutResult(), .partialResult(hostedUIError: busy))
        XCTAssertEqual(outcome.signedOutResult().partialErrors?.hostedUIError?.kind, .browserBusy(holder: .default))
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
            AuthClientSignOutResult.partialResult(hostedUIError: busy),
            .partialResult()
        )
    }

    /// - Given: a sign-out whose every attempt lost its race, with only a hosted-UI failure
    /// - When: its result is read
    /// - Then:
    ///    - it is `.failed(.storageUnavailable(.interrupted))` carrying the hosted-UI failure underneath
    func testAContendedSignOutCarriesTheHostedUIFailure() {
        let outcome = SessionSignOut.Outcome.contended(server: EngineSignOutOutcome(hostedUIError: busy))

        let error = failedSignOutError(outcome.result())
        XCTAssertEqual(error?.storageUnavailableReason, .interrupted)
        XCTAssertEqual((error?.underlyingError as? AuthClientError)?.kind, .browserBusy(holder: .default))
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
