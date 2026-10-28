//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
@testable import AmplifyFoundation
import AuthenticationServices
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The refusal of a hosted-UI sign-in while the session's previous call is still in progress, but neither holds the
/// system sheet nor is queued for it: before its lease (here, held just before it asks for the sheet). It is decided
/// from one read of the sheet lock, so it never says the call is queued when it is not, and never names the session as
/// holding a sheet nobody holds.
final class WebUISignInInProgressTests: XCTestCase {

    private var harness: ClientHarness!
    /// The window to anchor sheets to, made on first use: a process's first `UIWindow()` can block for minutes on a
    /// just-booted simulator.
    private var window: AuthClientPresentationAnchor {
        get async { await HostedUIFixtures.window() }
    }
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    /// Holds "work"'s calls just before they ask for the sheet, until opened.
    private let beforeAsking = Gate()

    override func setUp() async throws {
        harness = ClientHarness()
        let work = work
        let beforeAsking = beforeAsking
        harness.sheetLock = SystemSheetLock(beforeAcquire: { session in
            if session == work {
                await beforeAsking.pass()
            }
        })
    }

    override func tearDown() async throws {
        await beforeAsking.open()
        let holder = await harness.sheetLock.currentHolder
        XCTAssertNil(holder, "a test left the sheet held")
        await harness.waitForBaseline()
        harness = nil
    }

    private func client(_ sessionId: SessionID) throws -> AmplifyCognitoClient {
        try harness.client(sessionId, configuration: HostedUIFixtures.configuration)
    }

    private func startSignIn(
        _ client: AmplifyCognitoClient,
        options: WebUIOptions = WebUIOptions()
    ) async -> Task<AuthClientSignInResult, Error> {
        let window = await window
        return Task { try await client.signInWithWebUI(presentationAnchor: window, options: options) }
    }

    /// - Given: "work"'s hosted-UI sign-in in progress before it asks for the sheet, and no session holding the sheet
    /// - When: "work" asks again, with `.fail` and with `.wait(timeout:)`
    /// - Then:
    ///    - each second call is refused at once with `browserBusy` naming "work", the requester, since nobody holds the
    ///      sheet, and says its hosted-UI sign-in is in progress, not that it holds a sheet or waits for one
    ///    - the first then signs in, with one engine call
    func testADoubleTapBeforeTheSheetIsAskedForSaysTheSignInIsInProgress() async throws {
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let first = await startSignIn(client)
        try await beforeAsking.arrivals(1, within: 10)
        let holder = await harness.sheetLock.currentHolder
        XCTAssertNil(holder)

        for policy in [WebUIOptions.BrowserBusyPolicy.fail, .wait(timeout: 60)] {
            let error = await authClientError {
                try await startSignIn(client, options: WebUIOptions(whenBrowserBusy: policy)).value(within: 10)
            }
            XCTAssertEqual(error?.kind, .browserBusy(holder: work), "\(policy)")
            XCTAssertEqual(error?.errorDescription, "Session \"work\" already has a hosted-UI sign-in in progress.", "\(policy)")
            XCTAssertEqual(
                error?.recoverySuggestion,
                "Wait for it to finish, or cancel it, before starting another for the same session.",
                "\(policy)"
            )
        }

        await beforeAsking.open()
        let result = try await first.value(within: 10)
        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(engine.webUISignInCalls.count, 1)
    }

    /// - Given: "home" showing its hosted-UI sign-in, and "work"'s in progress before it asks for the sheet (with
    ///   `.fail`, so it never queues)
    /// - When: "work" asks again
    /// - Then:
    ///    - the second call is refused at once with `browserBusy` naming "home", which holds the sheet, and says "work"'s
    ///      hosted-UI sign-in is in progress, not that "work" is waiting for the sheet
    ///    - the first is then refused by the lock, as "home" still holds the sheet; nothing of "work"'s is shown
    func testADoubleTapWhileAnotherSessionHoldsTheSheetDoesNotSayItIsQueued() async throws {
        let homeClient = try client(home)
        let homeBrowser = FakeBrowser()
        try XCTUnwrap(harness.engine(for: home)).showWebUISignIns(in: homeBrowser)
        let homeSignIn = await startSignIn(homeClient)
        try await homeBrowser.shown.arrivals(1, within: 10)
        let client = try client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let first = await startSignIn(client)
        try await beforeAsking.arrivals(1, within: 10)
        let waiters = await harness.sheetLock.waiterCount
        XCTAssertEqual(waiters, 0)

        let error = await authClientError { try await startSignIn(client).value(within: 10) }

        XCTAssertEqual(error?.kind, .browserBusy(holder: home))
        XCTAssertEqual(
            error?.errorDescription,
            "Session \"work\" already has a hosted-UI sign-in in progress, and session \"home\" holds the system sheet."
        )
        await beforeAsking.open()
        let refused = await authClientError { try await first.value(within: 10) }
        XCTAssertEqual(refused?.kind, .browserBusy(holder: home))
        XCTAssertEqual(engine.webUISignInCalls.count, 0)
        homeBrowser.finishWithDefault()
        _ = try await homeSignIn.value(within: 10)
    }

    /// The reason's texts: it names the holder only when another session holds the sheet.
    ///
    /// - Given: the in-progress reason
    /// - When: it is built for holder alice and requester bob, and for bob as both
    /// - Then:
    ///    - both carry the holder given; only the first names alice
    func testTheInProgressReasonNamesOnlyAnotherHolder() {
        let alice = ClientFixtures.id("alice")
        let bob = ClientFixtures.id("bob")

        let other = AuthClientError.browserBusy(heldBy: alice, requestedBy: bob, reason: .signInInProgress)
        let itself = AuthClientError.browserBusy(heldBy: bob, requestedBy: bob, reason: .signInInProgress)

        XCTAssertEqual(other.kind, .browserBusy(holder: alice))
        XCTAssertEqual(itself.kind, .browserBusy(holder: bob))
        XCTAssertEqual(
            other.errorDescription,
            "Session \"bob\" already has a hosted-UI sign-in in progress, and session \"alice\" holds the system sheet."
        )
        XCTAssertEqual(itself.errorDescription, "Session \"bob\" already has a hosted-UI sign-in in progress.")
    }
}
#endif
