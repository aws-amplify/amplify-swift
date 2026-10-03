//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `signInWithWebUI` over the fake engine and the harness's own sheet lock: the lease rules, the commit order, cancellation and its mappings, the request.
final class WebUISignInTests: XCTestCase {

    private var harness: ClientHarness!
    private var window: AuthClientPresentationAnchor!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let webUser = AuthClientUser(username: "web-user", userId: "sub-web-user")

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

    private func client(_ sessionId: SessionID) throws -> AmplifyCognitoClient {
        try harness.client(sessionId, configuration: HostedUIFixtures.configuration)
    }

    /// Starts a sign-in on its own task, as an app's button does.
    private func startSignIn(
        _ client: AmplifyCognitoClient,
        options: WebUIOptions = WebUIOptions()
    ) -> Task<AuthClientSignInResult, Error> {
        let window = window!
        return Task { try await client.signInWithWebUI(presentationAnchor: window, options: options) }
    }

    private func waitForFreeSheet(file: StaticString = #filePath, line: UInt = #line) async {
        let lock = harness.sheetLock
        await waitUntil("the sheet is free", file: file, line: line) { await lock.currentHolder == nil }
    }

    // MARK: The lease and the commit

    /// The lease wraps exactly the engine call
    ///
    /// - Given: a signed-out session whose hosted-UI sign-in is showing its browser
    /// - When:
    ///    - the browser finishes
    /// - Then:
    ///    - while it shows, the session holds the sheet, and nothing is committed or sent
    ///    - after, the sheet is free, the record holds the user, the state is signed in and `.signedIn` was sent once
    func testTheLeaseCoversTheEngineCallAndTheCommitComesAfter() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser()
        engine.showWebUISignIns(in: browser)
        let events = StreamRecorder(client.listenToAuthEvents())
        _ = await client.currentSessionState()

        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        let holder = await harness.sheetLock.currentHolder
        XCTAssertEqual(holder, work)
        XCTAssertNil(try harness.storedRecord(work))
        XCTAssertEqual(events.received, [])

        browser.finishWithDefault()
        let result = try await signIn.value

        XCTAssertEqual(result.nextStep, .done)
        let after = await harness.sheetLock.currentHolder
        XCTAssertNil(after)
        XCTAssertEqual(try harness.storedRecord(work)?.userId, "sub-web-user")
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(webUser))
        await events.waitFor(1)
        XCTAssertEqual(events.received, [.signedIn])
    }

    /// A late `.done` after an interrupt is revoked, not committed
    ///
    /// - Given: a hosted-UI sign-in whose code exchange keeps running after its browser is cancelled
    /// - When:
    ///    - `cancelWebUISignIn()` interrupts it, and the flow then returns tokens
    /// - Then:
    ///    - the caller gets `.userCancelled` at once
    ///    - the late tokens are revoked with the hosted UI skipped, nothing is committed, no event is sent
    func testALateDoneAfterAnInterruptIsRevokedAndNotCommitted() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser(afterCancel: .keepRunning)
        engine.showWebUISignIns(in: browser)
        let events = StreamRecorder(client.listenToAuthEvents())

        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)
        await client.cancelWebUISignIn()

        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)

        let late = try XCTUnwrap(browser.defaultAnswer)
        browser.finishWithDefault()
        await waitForFreeSheet()
        guard case .done(let payload) = late else {
            return XCTFail("expected a done answer")
        }
        await waitUntil("the late tokens are revoked") { engine.revokeCalls == [payload] }
        XCTAssertEqual(engine.revokeHostedUIPlans, [.skip])
        XCTAssertNil(try harness.storedRecord(work))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(events.received, [])
    }

    /// A `.done` the body returned just before an interrupt is revoked
    ///
    /// - Given: a hosted-UI sign-in whose body has returned tokens, held before the lock releases its lease
    /// - When:
    ///    - `cancelWebUISignIn()` interrupts it there
    /// - Then:
    ///    - the caller gets `.userCancelled`; the tokens are revoked once, with the hosted UI skipped; nothing is
    ///      committed
    func testADoneReturnedJustBeforeAnInterruptIsRevoked() async throws {
        let held = Gate()
        harness.sheetLock = SystemSheetLock(beforeRelease: { _ in await held.pass() })
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let signIn = startSignIn(client)
        await held.waitForArrivals(1)
        await client.cancelWebUISignIn()

        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        await waitUntil("the returned tokens are revoked") { engine.revokeCalls.count == 1 }
        let revoked = try XCTUnwrap(engine.revokeCalls.first.flatMap(FakePayload.decode))
        XCTAssertEqual(revoked.username, "web-user")
        XCTAssertEqual(engine.revokeHostedUIPlans, [.skip])
        await held.open()
        await waitForFreeSheet()
        XCTAssertNil(try harness.storedRecord(work))
        XCTAssertEqual(engine.revokeCalls.count, 1)
    }

    // MARK: The sheet's policies

    /// - Given: session "work" showing its hosted-UI sign-in
    /// - When: session "home" asks for one with the default `.fail`
    /// - Then:
    ///    - it throws `browserBusy` naming "work", and its engine is never called
    func testABusySheetFailsNamingTheHolder() async throws {
        let workClient = try client(work)
        let homeClient = try client(home)
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: browser)
        let workSignIn = startSignIn(workClient)
        await browser.shown.waitForArrivals(1)

        let error = await authClientError { try await startSignIn(homeClient).value }

        XCTAssertEqual(error?.kind, .browserBusy(holder: work))
        XCTAssertEqual(harness.engine(for: home)?.webUISignInCalls.count, 0)
        browser.finishWithDefault()
        _ = try await workSignIn.value
    }

    /// - Given: session "work" showing its hosted-UI sign-in
    /// - When: session "home" asks for one with `.wait(timeout:)`
    /// - Then:
    ///    - it queues, and is shown once "work" has finished; both end signed in
    func testAWaitingSignInIsShownOnceTheHolderFinishes() async throws {
        let workClient = try client(work)
        let homeClient = try client(home)
        let workBrowser = FakeBrowser()
        let homeBrowser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: workBrowser)
        try XCTUnwrap(harness.engine(for: home)).showWebUISignIns(in: homeBrowser)
        let workSignIn = startSignIn(workClient)
        await workBrowser.shown.waitForArrivals(1)

        let homeSignIn = startSignIn(homeClient, options: WebUIOptions(whenBrowserBusy: .wait(timeout: 60)))
        let lock = harness.sheetLock
        await waitUntil("home queues") { await lock.waiterCount == 1 }
        XCTAssertEqual(harness.engine(for: home)?.webUISignInCalls.count, 0)

        workBrowser.finishWithDefault()
        _ = try await workSignIn.value
        await homeBrowser.shown.waitForArrivals(1)
        let holder = await lock.currentHolder
        XCTAssertEqual(holder, home)
        homeBrowser.finishWithDefault()
        _ = try await homeSignIn.value

        let homeState = await homeClient.currentSessionState()
        XCTAssertEqual(homeState, .signedIn(webUser))
    }

    /// First come first served with several waiters
    ///
    /// - Given: session "work" showing its hosted-UI sign-in; "home", then "team", queued with `.wait(timeout:)`
    /// - When: each finishes in turn
    /// - Then:
    ///    - "home" is shown next, then "team"; all three end signed in
    func testSeveralWaitersAreShownInTheOrderTheyQueued() async throws {
        let team = ClientFixtures.id("team")
        let sessions = [work, home, team]
        var clients: [AmplifyCognitoClient] = []
        var browsers: [FakeBrowser] = []
        for sessionId in sessions {
            clients.append(try client(sessionId))
            let browser = FakeBrowser()
            try XCTUnwrap(harness.engine(for: sessionId)).showWebUISignIns(in: browser)
            browsers.append(browser)
        }
        let lock = harness.sheetLock
        let first = startSignIn(clients[0])
        await browsers[0].shown.waitForArrivals(1)
        let second = startSignIn(clients[1], options: WebUIOptions(whenBrowserBusy: .wait(timeout: 60)))
        await waitUntil("home queues") { await lock.waiterCount == 1 }
        let third = startSignIn(clients[2], options: WebUIOptions(whenBrowserBusy: .wait(timeout: 60)))
        await waitUntil("team queues") { await lock.waiterCount == 2 }

        for (index, signIn) in [first, second, third].enumerated() {
            await browsers[index].shown.waitForArrivals(1)
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, sessions[index])
            for later in browsers.dropFirst(index + 1) {
                XCTAssertEqual(later.defaultAnswer == nil, true, "a later session was shown out of turn")
            }
            browsers[index].finishWithDefault()
            _ = try await signIn.value
        }
        for client in clients {
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedIn(webUser))
        }
    }

    /// The same session asking again while its cancelled browser is still closing
    ///
    /// - Given: a session whose hosted-UI sign-in was cancelled and is still unwinding (it holds the sheet)
    /// - When: the session asks again with `.fail`
    /// - Then:
    ///    - it is refused with `browserBusy` naming itself; once the first has unwound, the sheet is free
    func testTheSameSessionIsRefusedWhileItsBrowserCloses() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser(afterCancel: .keepRunning)
        engine.showWebUISignIns(in: browser)
        let first = startSignIn(client)
        await browser.shown.waitForArrivals(1)
        await client.cancelWebUISignIn()
        _ = await authClientError { try await first.value }

        let error = await authClientError { try await startSignIn(client).value }

        XCTAssertEqual(error?.kind, .browserBusy(holder: work))
        XCTAssertEqual(engine.webUISignInCalls.count, 1)
        browser.finish(.failure(CancellationError()))
        await waitForFreeSheet()
    }

    /// A double tap
    ///
    /// - Given: a hosted-UI sign-in of this session showing its browser
    /// - When: the session asks again, with `.fail` and with `.wait(timeout:)`, and the first is then cancelled
    /// - Then:
    ///    - each second call is refused at once with `browserBusy` naming this session, whatever the policy,
    ///      and no second browser is ever shown
    func testADoubleTapIsRefusedWhateverThePolicy() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser()
        engine.showWebUISignIns(in: browser)
        let first = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        for policy in [WebUIOptions.BrowserBusyPolicy.fail, .wait(timeout: 60)] {
            let error = await authClientError { try await startSignIn(client, options: WebUIOptions(whenBrowserBusy: policy)).value }
            XCTAssertEqual(error?.kind, .browserBusy(holder: work))
            XCTAssertEqual(error?.errorDescription, "Session \"work\" already has a system sheet in progress.")
        }
        await client.cancelWebUISignIn()
        _ = await authClientError { try await first.value }

        XCTAssertEqual(engine.webUISignInCalls.count, 1)
        await waitForFreeSheet()
    }

    // MARK: Refusals

    /// - Given: a session signed in with a password
    /// - When: it asks for a hosted-UI sign-in
    /// - Then:
    ///    - it throws the plugin's `invalidState`, takes no lease, and the engine is not called
    func testASignedInSessionIsRefused() async throws {
        let client = try client(work)
        try await client.signInForTest("alice")

        let error = await authClientError { try await startSignIn(client).value }

        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(
            error?.errorDescription,
            "There is already a user in signedIn state. SignOut the user first before calling signIn"
        )
        XCTAssertEqual(harness.engine(for: work)?.webUISignInCalls.count, 0)
    }

    /// - Given: a configuration with a user pool but no hosted UI, and one with no user pool
    /// - When: each asks for a hosted-UI sign-in
    /// - Then:
    ///    - each throws `configuration`, and the engine is not called
    func testAConfigurationWithoutAHostedUIIsRefused() async throws {
        let noHostedUI = try harness.client(work, configuration: ClientFixtures.configuration)
        let noUserPool = try harness.client(home, configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let window = window!

        let first = await authClientError { try await noHostedUI.signInWithWebUI(presentationAnchor: window) }
        let second = await authClientError { try await noUserPool.signInWithWebUI(presentationAnchor: window) }

        XCTAssertEqual(first?.kind, .configuration)
        XCTAssertEqual(second?.kind, .configuration)
        XCTAssertEqual(harness.engine(for: work)?.webUISignInCalls.count, 0)
        XCTAssertEqual(harness.engine(for: home)?.webUISignInCalls.count, 0)
    }

    // MARK: A pending challenge, and the session's sign-in lock

    /// A password sign-in waiting on a challenge is cancelled first, and `cancelWebUISignIn()` does
    /// not reach a call still waiting for the session's sign-in lock
    ///
    /// - Given: a password sign-in held in the engine, and a hosted-UI sign-in queued behind it on the session's
    ///   sign-in lock
    /// - When:
    ///    - `cancelWebUISignIn()` runs while the hosted-UI call waits; then the password sign-in stops on an
    ///      MFA challenge
    /// - Then:
    ///    - the hosted-UI call goes on: it cancels the pending challenge, so the state is signed out while the
    ///      browser shows, then signed in
    func testAPendingChallengeIsCancelledFirstAndACancelBeforeTheLockIsANoOp() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdSignIns(on: latch)
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        let browser = FakeBrowser()
        engine.showWebUISignIns(in: browser)

        let password = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)
        let webUI = startSignIn(client)
        await client.cancelWebUISignIn()
        await latch.open()
        _ = try await password.value

        await browser.shown.waitForArrivals(1)
        let whileShowing = await client.currentSessionState()
        XCTAssertEqual(whileShowing, .signedOut)
        XCTAssertEqual(engine.cancelPendingSignInCount, 1)
        browser.finishWithDefault()
        _ = try await webUI.value

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(webUser))
    }

    // MARK: Cancellation

    /// - Given: a hosted-UI sign-in showing its browser
    /// - When: the session is signed out
    /// - Then:
    ///    - the browser is cancelled, the call throws the sign-in-cancelled `invalidState`, and the sheet is free
    func testSigningTheSessionOutCancelsItsBrowser() async throws {
        let client = try client(work)
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: browser)
        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        _ = await client.signOut()

        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .invalidState)
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        XCTAssertEqual(browser.cancelCount, 1)
        await waitForFreeSheet()
    }

    /// An ending that lands before the lease
    ///
    /// - Given: a hosted-UI sign-in held while it reads the other sessions' users, before the lease
    /// - When: the session is signed out there
    /// - Then:
    ///    - the sign-in throws the sign-in-cancelled `invalidState`, and the engine's hosted UI is never called
    func testASignOutBeforeTheLeaseShowsNothing() async throws {
        _ = try harness.signIn(home, .signedIn("bob"))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let listing = Stall()
        harness.keychain.onceAfterReading(harness.store().sessionAccount(for: home)) { listing.block() }
        let signIn = startSignIn(client, options: WebUIOptions(identityExpectation: .distinctFromOtherSessions))
        await waitUntil("the listing is held") { listing.hasBeenReached }

        let signOut = Task { await client.signOut() }
        await waitUntil("the sign-out has ended the session") { engine.cancelPendingSignInCount == 1 }
        listing.release()

        let error = await authClientError { try await signIn.value }
        _ = await signOut.value
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        XCTAssertEqual(engine.webUISignInCalls.count, 0)
    }

    /// An earlier ending never stops a later flow
    ///
    /// - Given: a sign-out that has moved the session's epoch and is held before the engine hears of it
    /// - When: a hosted-UI sign-in starts and shows its browser, and the sign-out then finishes
    /// - Then:
    ///    - the browser is not cancelled; the sign-in finishes and signs the session in
    func testAnEarlierSignOutDoesNotStopALaterFlow() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let browser = FakeBrowser()
        engine.showWebUISignIns(in: browser)
        let held = Gate()
        engine.holdCancels(on: held)
        _ = await client.currentSessionState()
        let signOut = Task { await client.signOut() }
        await held.waitForArrivals(1)
        engine.holdCancels(on: nil)

        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)
        await held.open()
        _ = await signOut.value
        await Task.yield()

        XCTAssertEqual(browser.cancelCount, 0)
        let holder = await harness.sheetLock.currentHolder
        XCTAssertEqual(holder, work)
        browser.finishWithDefault()
        _ = try await signIn.value
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(webUser))
    }

    /// - Given: a hosted-UI sign-in showing its browser
    /// - When: the calling task is cancelled
    /// - Then:
    ///    - the browser is cancelled, the call throws `CancellationError`, and the sheet is free
    func testCancellingTheCallerThrowsCancellationError() async throws {
        let client = try client(work)
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: browser)
        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        signIn.cancel()

        do {
            _ = try await signIn.value
            XCTFail("expected CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError, "got \(error)")
        }
        XCTAssertEqual(browser.cancelCount, 1)
        await waitForFreeSheet()
    }

    /// - Given: a hosted-UI sign-in queued behind a password sign-in on the session's sign-in lock
    /// - When: the calling task is cancelled there
    /// - Then:
    ///    - it throws `CancellationError`, and the engine's hosted UI is never called
    func testACallerCancelledBeforeTheLeaseShowsNothing() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdSignIns(on: latch)
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        let password = Task { try await client.signInForTest("alice") }
        await latch.waitForArrivals(1)

        let webUI = startSignIn(client)
        webUI.cancel()
        await latch.open()
        _ = try await password.value

        do {
            _ = try await webUI.value
            XCTFail("expected CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError, "got \(error)")
        }
        XCTAssertEqual(engine.webUISignInCalls.count, 0)
    }

    /// A caller cancelled after the sign-in lock but before the lease, while another session holds the sheet
    ///
    /// - Given: session "team" showing its hosted-UI sign-in; this session's call held while it reads the other
    ///   sessions' users, before the lease
    /// - When: the calling task is cancelled there, with `.fail` and with `.wait`
    /// - Then:
    ///    - each throws `CancellationError`, not `browserBusy`, and promptly: no `.wait` is left queued, and the
    ///      engine's hosted UI is never called
    func testACallerCancelledBeforeTheLeaseOfABusySheetIsCancelled() async throws {
        let team = ClientFixtures.id("team")
        _ = try harness.signIn(home, .signedIn("bob"))
        let teamClient = try client(team)
        let teamBrowser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: team)).showWebUISignIns(in: teamBrowser)
        let teamSignIn = startSignIn(teamClient)
        await teamBrowser.shown.waitForArrivals(1)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let homeAccount = harness.store().sessionAccount(for: home)

        for policy in [WebUIOptions.BrowserBusyPolicy.fail, .wait(timeout: 60)] {
            let listing = Stall()
            harness.keychain.onceAfterReading(homeAccount) { listing.block() }
            let signIn = startSignIn(client, options: WebUIOptions(whenBrowserBusy: policy, identityExpectation: .distinctFromOtherSessions))
            await waitUntil("the listing is held") { listing.hasBeenReached }

            signIn.cancel()
            listing.release()

            do {
                _ = try await signIn.value
                XCTFail("expected CancellationError")
            } catch {
                XCTAssertTrue(error is CancellationError, "got \(error)")
            }
            let waiters = await harness.sheetLock.waiterCount
            XCTAssertEqual(waiters, 0)
        }
        XCTAssertEqual(engine.webUISignInCalls.count, 0)
        teamBrowser.finishWithDefault()
        _ = try await teamSignIn.value
    }

    /// - Given: a hosted-UI sign-in showing its browser
    /// - When: `cancelWebUISignIn()` runs, twice
    /// - Then:
    ///    - the browser is cancelled once, the call throws `.userCancelled`, and the sheet is free
    func testCancelWebUISignInThrowsUserCancelled() async throws {
        let client = try client(work)
        let browser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: browser)
        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        await client.cancelWebUISignIn()
        await client.cancelWebUISignIn()

        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        XCTAssertEqual(browser.cancelCount, 1)
        await waitForFreeSheet()
    }

    /// - Given: a hosted-UI sign-in showing its browser
    /// - When: the sheet is reset
    /// - Then:
    ///    - the reset names the holder and frees the sheet at once; the call throws `.userCancelled`
    func testResettingTheSheetThrowsUserCancelled() async throws {
        let client = try client(work)
        let browser = FakeBrowser(afterCancel: .keepRunning)
        try XCTUnwrap(harness.engine(for: work)).showWebUISignIns(in: browser)
        let signIn = startSignIn(client)
        await browser.shown.waitForArrivals(1)

        let reset = await harness.sheetLock.reset()

        XCTAssertEqual(reset, work)
        let holder = await harness.sheetLock.currentHolder
        XCTAssertNil(holder)
        let error = await authClientError { try await signIn.value }
        XCTAssertEqual(error?.kind, .userCancelled)
        browser.finish(.failure(CancellationError()))
    }

    /// - Given: no hosted-UI sign-in
    /// - When: `cancelWebUISignIn()` and the static sheet members are used
    /// - Then:
    ///    - nothing happens, and the process-wide sheet reports no holder
    func testTheRecoveryToolsAreNoOpsWhenNothingIsShowing() async throws {
        let client = try client(work)
        await client.cancelWebUISignIn()
        let holder = await AmplifyCognitoClient.systemSheetHolder
        XCTAssertNil(holder)
        let reset = await AmplifyCognitoClient.resetSystemSheet()
        XCTAssertNil(reset)
    }

    // MARK: The request

    /// - Given: a social sign-in for Google with an `idpIdentifier`, a prompt list, and the defaults
    /// - When: the engine receives them
    /// - Then:
    ///    - provider and `idpIdentifier` both reach it (the engine applies the precedence), the prompt is
    ///      space-separated in order, an empty prompt list is sent as none, and ephemeral is the default
    func testTheRequestCarriesTheOptions() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        engine.scriptWebUISignIn { _, _ in throw AuthClientError.userCancelled("closed", "retry") }

        _ = await authClientError {
            try await client.signInWithWebUI(
                for: .google,
                presentationAnchor: window,
                options: WebUIOptions(
                    prefersEphemeralSession: false,
                    scopes: ["openid"],
                    idpIdentifier: "corp",
                    language: "fr",
                    loginHint: "a@example.com",
                    prompt: [.login, .consent],
                    resource: "https://api.example.com"
                )
            )
        }
        _ = await authClientError {
            try await client.signInWithWebUI(presentationAnchor: window, options: WebUIOptions(prompt: []))
        }

        let calls = engine.webUISignInCalls
        XCTAssertEqual(calls.count, 2)
        let social = try XCTUnwrap(calls.first?.request.options)
        XCTAssertEqual(social.provider, .google)
        XCTAssertEqual(social.idpIdentifier, "corp")
        XCTAssertEqual(social.scopes, ["openid"])
        XCTAssertFalse(social.prefersEphemeralSession)
        XCTAssertEqual(social.language, "fr")
        XCTAssertEqual(social.loginHint, "a@example.com")
        XCTAssertEqual(social.prompt, "login consent")
        XCTAssertEqual(social.resource, "https://api.example.com")
        let plain = try XCTUnwrap(calls.last?.request.options)
        XCTAssertNil(plain.prompt)
        XCTAssertNil(plain.provider)
        XCTAssertNil(plain.scopes)
        XCTAssertTrue(plain.prefersEphemeralSession)
        XCTAssertEqual(calls.last?.request.identity, EngineIdentityPolicy.none)
    }

    /// - Given: two sign-ins without a nonce, one with the caller's, and one with an empty one
    /// - When: the engine receives them
    /// - Then:
    ///    - each minted nonce is 32 random bytes in base64url (43 characters, no padding) and they differ; the
    ///      caller's is sent as it is; an empty one is replaced by a minted one
    func testANonceIsMintedPerCallAndTheCallersIsKept() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let window = window!
        engine.scriptWebUISignIn { _, _ in throw AuthClientError.userCancelled("closed", "retry") }

        for options in [WebUIOptions(), WebUIOptions(), WebUIOptions(nonce: "caller-nonce"), WebUIOptions(nonce: "")] {
            _ = await authClientError { try await client.signInWithWebUI(presentationAnchor: window, options: options) }
        }

        let nonces = engine.webUISignInCalls.map(\.request.options.nonce)
        XCTAssertEqual(nonces.count, 4)
        XCTAssertNotEqual(nonces[0], nonces[1])
        for minted in [nonces[0], nonces[1], nonces[3]] {
            XCTAssertEqual(minted.count, 43)
            XCTAssertNil(minted.rangeOfCharacter(from: CharacterSet(charactersIn: "+/=")))
            XCTAssertEqual(Data(base64URL: minted)?.count, 32)
        }
        XCTAssertEqual(nonces[2], "caller-nonce")
    }

    /// - Given: an expectation of a user
    /// - When: the engine receives it
    /// - Then:
    ///    - the policy expects that identity and excludes nobody
    func testAMatchesExpectationReachesTheEngine() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await startSignIn(client, options: WebUIOptions(identityExpectation: .matches("sub-bob"))).value

        XCTAssertEqual(engine.webUISignInCalls.first?.request.identity, EngineIdentityPolicy(expectedIdentity: "sub-bob"))
    }

    // MARK: `.distinctFromOtherSessions`

    /// - Given: this session signed in as "carol"; "home" signed in (its record names its user); "team"
    ///   signed in with a record naming no user; "old" signed out; "visitor" a guest
    /// - When: the policy for `.distinctFromOtherSessions` is built
    /// - Then:
    ///    - the excluded users are home's and team's (read from its credentials), never this session's own, and
    ///      none of the signed-out or guest rows'; each maps to the session holding it
    func testDistinctFromOtherSessionsExcludesTheOtherSignedInUsers() async throws {
        let team = ClientFixtures.id("team")
        let old = ClientFixtures.id("old")
        let visitor = ClientFixtures.id("visitor")
        let store = harness.store()
        _ = try harness.signIn(work, .signedIn("carol"))
        _ = try harness.signIn(home, .signedIn("bob"))
        _ = try store.write(FakePayload.signedIn("dave").record(includeUserId: false), for: team, expecting: nil)
        _ = try store.write(.signedOut(label: nil, username: "erin", userId: "sub-erin"), for: old, expecting: nil)
        _ = try store.write(FakePayload.guest().record(), for: visitor, expecting: nil)
        let client = try client(work)

        let (policy, holders) = try await client.core.identityPolicy(for: .distinctFromOtherSessions)

        XCTAssertEqual(policy, EngineIdentityPolicy(excludedSubjects: ["sub-bob", "sub-dave"]))
        XCTAssertEqual(holders, ["sub-bob": home, "sub-dave": team])
    }

    /// - Given: another signed-in session, "home"
    /// - When: this signed-out session signs in with `.distinctFromOtherSessions`
    /// - Then:
    ///    - the engine is asked to exclude home's user
    func testDistinctFromOtherSessionsReachesTheEngine() async throws {
        _ = try harness.signIn(home, .signedIn("bob"))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await startSignIn(client, options: WebUIOptions(identityExpectation: .distinctFromOtherSessions)).value

        XCTAssertEqual(engine.webUISignInCalls.first?.request.identity, EngineIdentityPolicy(excludedSubjects: ["sub-bob"]))
    }

    /// - Given: another signed-in session, "home", whose user is refused by the engine
    /// - When: this session signs in with `.distinctFromOtherSessions`
    /// - Then:
    ///    - it throws `.unexpectedIdentity` with no expectation and the returned user, its description naming
    ///      "home"; nothing is committed
    func testTheRefusalNamesTheSessionHoldingTheUser() async throws {
        _ = try harness.signIn(home, .signedIn("bob"))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let bob = AuthClientUser(username: "bob", userId: "sub-bob")
        engine.scriptWebUISignIn { _, _ in
            throw AuthClientError.unexpectedIdentity(expected: nil, returned: bob, "a different user", "retry with login")
        }

        let error = await authClientError {
            try await startSignIn(client, options: WebUIOptions(identityExpectation: .distinctFromOtherSessions)).value
        }

        XCTAssertEqual(error?.kind, .unexpectedIdentity(expected: nil, returned: bob))
        XCTAssertEqual(
            error?.errorDescription,
            "The hosted UI sign-in returned the user who is signed in to session \"home\", so nobody was signed in."
        )
        XCTAssertEqual(error?.recoverySuggestion, "retry with login")
        XCTAssertNil(try harness.storedRecord(work))
    }

    /// - Given: `.default` on the Auth plugin's record, its own, signed in
    /// - When: another session signs in with `.distinctFromOtherSessions`
    /// - Then:
    ///    - the plugin record's user, read through `describe`, is excluded
    func testDistinctFromOtherSessionsExcludesTheDefaultSessionsPluginRecord() async throws {
        let store = harness.store()
        let account = try XCTUnwrap(store.pluginSessionAccount(for: .default))
        harness.keychain.put(FakePayload.signedIn("frank").data, account)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await startSignIn(client, options: WebUIOptions(identityExpectation: .distinctFromOtherSessions)).value

        XCTAssertEqual(engine.webUISignInCalls.first?.request.identity.excludedSubjects, ["sub-frank"])
    }

    /// `.distinctFromOtherSessions` fails closed
    ///
    /// - Given: another session's saved record that cannot be read (a locked keychain)
    /// - When: this session signs in with `.distinctFromOtherSessions`
    /// - Then:
    ///    - it throws `storageUnavailable`, takes no sheet, and the engine's hosted UI is never called: a session
    ///      that cannot be read could hold the user that comes back
    func testDistinctFromOtherSessionsFailsClosedWhenARecordCannotBeRead() async throws {
        _ = try harness.signIn(home, .signedIn("bob"))
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        harness.keychain.failingReads(of: harness.store().sessionAccount(for: home), with: errSecInteractionNotAllowed)

        let error = await authClientError {
            try await startSignIn(client, options: WebUIOptions(identityExpectation: .distinctFromOtherSessions)).value
        }

        harness.keychain.clearFailures()
        XCTAssertNotNil(error?.storageUnavailableReason)
        XCTAssertEqual(engine.webUISignInCalls.count, 0)
    }

    // MARK: Errors

    /// - Given: the engine throws each hosted-UI failure
    /// - When: the sign-in runs
    /// - Then:
    ///    - each reaches the caller as it is, the session stays signed out, and the sheet is free
    func testEngineFailuresReachTheCaller() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let failures: [AuthClientError] = [
            .validation(field: "presentationAnchor", "gone", "retry"),
            .userCancelled("closed", "retry"),
            .invalidState("no window", "retry"),
            .service(nil, "unverified", "retry"),
            .configuration("bad redirect", "fix")
        ]
        for failure in failures {
            engine.scriptWebUISignIn { _, _ in throw failure }
            let error = await authClientError { try await startSignIn(client).value }
            XCTAssertEqual(error?.kind, failure.kind)
        }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: a sign-in whose result cannot be saved (the record's writes fail)
    /// - When: the sign-in finishes
    /// - Then:
    ///    - it throws `storageUnavailable`, and the issued tokens are revoked
    func testAResultThatCannotBeSavedIsRevoked() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        _ = await client.currentSessionState()
        harness.keychain.failing(.write, with: errSecInteractionNotAllowed)

        let error = await authClientError { try await startSignIn(client).value }

        harness.keychain.clearFailures()
        XCTAssertNotNil(error?.storageUnavailableReason)
        XCTAssertEqual(engine.revokeCalls.count, 1)
        XCTAssertEqual(engine.revokeHostedUIPlans, [.skip])
    }
}

extension Data {

    /// base64url without padding, for assertions.
    init?(base64URL: String) {
        var base64 = base64URL.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        self.init(base64Encoded: base64)
    }
}

#endif
