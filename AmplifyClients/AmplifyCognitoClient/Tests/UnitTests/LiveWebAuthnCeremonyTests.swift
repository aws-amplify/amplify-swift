//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// WebAuthn ceremonies over the live engine and scripted Cognito, with a passkey sheet
/// that presents nothing: associate, passkey sign-in and the `WEB_AUTHN` selection, the Cognito requests
/// they send, where the sheet lease is held, and how each failure reaches the caller.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class LiveWebAuthnCeremonyTests: XCTestCase {

    private var harness: LiveEngineHarness!
    private var clientHarness: ClientHarness!
    private var sheet: FakePasskeySheet!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = LiveEngineHarness()
        clientHarness = ClientHarness()
        sheet = FakePasskeySheet()
    }

    override func tearDown() async throws {
        harness.cognito.assertConsumed()
        await clientHarness.waitForBaseline()
        harness = nil
        clientHarness = nil
        sheet = nil
    }

    // MARK: Associate

    /// Lease point 4 through the live engine.
    ///
    /// - Given: alice signed in over the live engine, and Cognito answering `StartWebAuthnRegistration` and
    ///   `CompleteWebAuthnRegistration`
    /// - When:
    ///    - she associates a passkey with a window
    /// - Then:
    ///    - Cognito gets `StartWebAuthnRegistration` then `CompleteWebAuthnRegistration`, both with her access
    ///      token as the session holds it, the second with the ceremony's credential; nothing else is sent
    ///    - one sheet was made, on the main thread, over the window, while the session held the sheet lease;
    ///      the lease is free afterwards, and the session's record is unchanged
    func testAssociateRegistersAPasskeyUnderTheSheetLease() async throws {
        let client = try liveClient()
        try await signIn(client)
        let before = try clientHarness.storedRecord(work)
        let window = await WebAuthnFixtures.window()
        let lock = clientHarness.sheetLock
        let holder = TestBox<SessionID?>(nil)
        sheet.answer { [lock] in
            let current = await lock.currentHolder
            holder.with { $0 = current }
        }
        harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in WebAuthnFixtures.startRegistration() }
        harness.cognito.once("CompleteWebAuthnRegistration") { (_: CompleteWebAuthnRegistrationInput) in CompleteWebAuthnRegistrationOutput() }

        try await client.associateWebAuthnCredential(presentationAnchor: window)

        let token = LiveEngineFixtures.jwt("alice", use: "access")
        XCTAssertEqual(harness.cognito.operations, ["StartWebAuthnRegistration", "CompleteWebAuthnRegistration"])
        XCTAssertEqual(harness.cognito.inputs("StartWebAuthnRegistration", as: StartWebAuthnRegistrationInput.self).map(\.accessToken), [token])
        let complete = harness.cognito.inputs("CompleteWebAuthnRegistration", as: CompleteWebAuthnRegistrationInput.self)
        XCTAssertEqual(complete.map(\.accessToken), [token])
        XCTAssertNotNil(complete.first?.credential)
        XCTAssertEqual(sheet.ceremonies.count, 1)
        XCTAssertEqual(sheet.ceremonies.first?.madeOnMainThread, true)
        let madeOverWindow = sheet.ceremonies.first?.anchor === window
        XCTAssertTrue(madeOverWindow)
        XCTAssertEqual(holder.value, work)
        let free = await lock.currentHolder
        XCTAssertNil(free)
        XCTAssertEqual(try clientHarness.storedRecord(work), before)
    }

    /// Associate's errors: the device's failures are never `.service`, and Cognito is not asked to
    /// complete anything.
    ///
    /// - Given: alice signed in, and Cognito answering `StartWebAuthnRegistration`
    /// - When:
    ///    - the sheet answers `.canceled` (the user closed it), code 1006 (a passkey already exists), `.failed`;
    ///      and, separately, Cognito's options cannot be read
    /// - Then:
    ///    - `.userCancelled`, `.webAuthnCeremonyFailed(.credentialAlreadyExists)` and
    ///      `.webAuthnCeremonyFailed(.failed)`, each with the `ASAuthorizationError` underneath; unreadable
    ///      options are `.webAuthnCeremonyFailed(.invalidCredential)` with no sheet; no
    ///      `CompleteWebAuthnRegistration`, and the lease is free after each
    func testAssociateMapsTheCeremonysFailures() async throws {
        let client = try liveClient()
        try await signIn(client)
        let window = await WebAuthnFixtures.window()
        let cases: [(ASAuthorizationError.Code, AuthClientError.Kind)] = [
            (.canceled, .userCancelled),
            (ASAuthorizationError.Code(rawValue: 1_006) ?? .unknown, .webAuthnCeremonyFailed(.credentialAlreadyExists)),
            (.failed, .webAuthnCeremonyFailed(.failed))
        ]

        for (code, kind) in cases {
            harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in WebAuthnFixtures.startRegistration() }
            sheet.fail(with: code)
            let error = await authClientError { try await client.associateWebAuthnCredential(presentationAnchor: window) }
            XCTAssertEqual(error?.kind, kind, "\(code.rawValue)")
            XCTAssertEqual((error?.underlyingError as? ASAuthorizationError)?.code, code, "\(code.rawValue)")
            let free = await clientHarness.sheetLock.currentHolder
            XCTAssertNil(free)
        }
        harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in WebAuthnFixtures.unreadableRegistration() }
        let unreadable = await authClientError { try await client.associateWebAuthnCredential(presentationAnchor: window) }

        XCTAssertEqual(unreadable?.kind, .webAuthnCeremonyFailed(.invalidCredential))
        XCTAssertTrue(unreadable?.underlyingError is AnyWebAuthnCredentialError)
        XCTAssertEqual(sheet.ceremonies.count, cases.count)
        XCTAssertFalse(harness.cognito.operations.contains("CompleteWebAuthnRegistration"))
    }

    /// Cognito's WebAuthn answers go through `.service`, one to one.
    ///
    /// - Given: alice signed in
    /// - When:
    ///    - `StartWebAuthnRegistration` fails with each of the seven WebAuthn exceptions
    /// - Then:
    ///    - each is `.service` with its code, and no sheet is made
    func testAssociateMapsCognitosWebAuthnAnswers() async throws {
        let client = try liveClient()
        try await signIn(client)
        let window = await WebAuthnFixtures.window()
        let cases: [(Error, AuthClientServiceErrorCode)] = [
            (WebAuthnNotEnabledException(message: "m"), .webAuthnNotEnabled),
            (WebAuthnCredentialNotSupportedException(message: "m"), .webAuthnNotSupported),
            (WebAuthnConfigurationMissingException(message: "m"), .webAuthnConfigurationMissing),
            (WebAuthnChallengeNotFoundException(message: "m"), .webAuthnChallengeNotFound),
            (WebAuthnClientMismatchException(message: "m"), .webAuthnClientMismatch),
            (WebAuthnOriginNotAllowedException(message: "m"), .webAuthnOriginNotAllowed),
            (WebAuthnRelyingPartyMismatchException(message: "m"), .webAuthnRelyingPartyMismatch)
        ]

        for (exception, code) in cases {
            let thrown = SendableError(exception)
            harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) -> StartWebAuthnRegistrationOutput in
                throw thrown.error
            }
            let error = await authClientError { try await client.associateWebAuthnCredential(presentationAnchor: window) }
            XCTAssertEqual(error?.kind, .service(code))
        }
        XCTAssertEqual(sheet.ceremonies.count, 0)
    }

    /// A window that has gone by the time the ceremony starts presents nothing.
    ///
    /// - Given: alice signed in, and a box whose window has been released
    /// - When:
    ///    - the core associates a passkey over it
    /// - Then:
    ///    - it throws `.validation(field: "presentationAnchor")`, no sheet is made, and nothing is completed
    func testAssociateOverAGoneWindowPresentsNothing() async throws {
        let client = try liveClient()
        try await signIn(client)
        let gone = await WebAuthnFixtures.goneWindowBox()
        harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in WebAuthnFixtures.startRegistration() }

        let error = await authClientError { try await client.core.associateWebAuthnCredential(anchor: gone) }

        XCTAssertEqual(error?.kind, .validation(field: "presentationAnchor"))
        XCTAssertEqual(sheet.ceremonies.count, 0)
        XCTAssertEqual(harness.cognito.operations, ["StartWebAuthnRegistration"])
    }

    /// The caller cancelling associate closes its sheet: `CancellationError`, never `.userCancelled`.
    ///
    /// - Given: alice signed in, and her associate's sheet up
    /// - When:
    ///    - the calling task is cancelled
    /// - Then:
    ///    - associate throws `CancellationError`; the sheet's ceremony saw the cancellation; nothing is
    ///      completed; the lease is free once the ceremony has unwound
    func testCancellingAssociateClosesItsSheet() async throws {
        let client = try liveClient()
        try await signIn(client)
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        sheet.answer(with: held.answer)
        harness.cognito.once("StartWebAuthnRegistration") { (_: StartWebAuthnRegistrationInput) in WebAuthnFixtures.startRegistration() }

        let associate = Task { try await client.associateWebAuthnCredential(presentationAnchor: window) }
        try await held.up()
        associate.cancel()

        await assertThrowsAsync({ try await associate.value(within: 10) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await waitUntil("the cancelled ceremony has unwound and freed the sheet") {
            await self.clientHarness.sheetLock.currentHolder == nil
        }
        XCTAssertEqual(sheet.cancelled, 1)
        XCTAssertEqual(harness.cognito.operations, ["StartWebAuthnRegistration"])
    }

    // MARK: Passkey sign-in

    /// Lease point 1: `USER_AUTH` preferring `WEB_AUTHN`, through the live engine.
    ///
    /// - Given: Cognito answering `InitiateAuth` with a `WEB_AUTHN` challenge and its options, then the
    ///   credential with tokens, and the identity pool
    /// - When:
    ///    - alice signs in with a window, `.userAuth(preferredFirstFactor: .webAuthn)` and no password
    /// - Then:
    ///    - `InitiateAuth` prefers `WEB_AUTHN`; the one sheet is made on the main thread over the window,
    ///      under the lease; `RespondToAuthChallenge` answers `WEB_AUTHN` with the sheet's credential
    ///    - the sign-in is `.done`, the session is signed in as alice, and the lease is free
    func testAPasskeySignInWithThePreferenceSignsIn() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        let lock = clientHarness.sheetLock
        let holder = TestBox<SessionID?>(nil)
        sheet.answer { [lock] in
            let current = await lock.currentHolder
            holder.with { $0 = current }
        }
        scriptWebAuthnSignIn()

        let result = try await client.signIn(
            username: "alice",
            presentationAnchor: window,
            options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
        )

        XCTAssertEqual(result.nextStep, .done)
        let initiate = harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self)
        XCTAssertEqual(initiate.first?.authFlow, .userAuth)
        XCTAssertEqual(initiate.first?.authParameters?["PREFERRED_CHALLENGE"], "WEB_AUTHN")
        let respond = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self)
        XCTAssertEqual(respond.map(\.challengeName), [.webAuthn])
        let credential = try XCTUnwrap(respond.first?.challengeResponses?["CREDENTIAL"])
        XCTAssertEqual(try Self.json(credential), try Self.json(WebAuthnFixtures.assertionAnswer()))
        XCTAssertEqual(sheet.ceremonies.count, 1)
        XCTAssertEqual(sheet.ceremonies.first?.madeOnMainThread, true)
        let madeOverWindow = sheet.ceremonies.first?.anchor === window
        XCTAssertTrue(madeOverWindow)
        XCTAssertEqual(holder.value, work)
        let state = await client.currentSessionState()
        guard case .signedIn(let user) = state else {
            return XCTFail("expected signed in, got \(state)")
        }
        XCTAssertEqual(user.username, "alice")
        let free = await lock.currentHolder
        XCTAssertNil(free)
    }

    /// Lease point 3: Cognito answering `WEB_AUTHN` to a sign-in with no preference asserts over the window.
    ///
    /// - Given: Cognito answering `InitiateAuth` (no preference) with a `WEB_AUTHN` challenge, then tokens
    /// - When:
    ///    - alice signs in with a window and `.userAuth(preferredFirstFactor: nil)`
    /// - Then:
    ///    - `InitiateAuth` prefers nothing; the one sheet is made over the window; the sign-in is `.done`
    func testAWebAuthnChallengeWithoutAPreferenceAssertsOverTheWindow() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        scriptWebAuthnSignIn()

        let result = try await client.signIn(
            username: "alice",
            presentationAnchor: window,
            options: .init(authFlowType: .userAuth(preferredFirstFactor: nil))
        )

        XCTAssertEqual(result.nextStep, .done)
        XCTAssertNil(harness.cognito.inputs("InitiateAuth", as: InitiateAuthInput.self).first?.authParameters?["PREFERRED_CHALLENGE"])
        XCTAssertEqual(sheet.ceremonies.count, 1)
        XCTAssertTrue(sheet.ceremonies.first?.anchor === window)
    }

    /// Lease point 2: the `WEB_AUTHN` selection asserts over the sign-in's window, or over the
    /// confirmation's own.
    ///
    /// - Given: Cognito answering `InitiateAuth` with `SELECT_CHALLENGE` offering `WEB_AUTHN`, the selection
    ///   with a `WEB_AUTHN` challenge, and the credential with tokens; twice
    /// - When:
    ///    - alice signs in with window A and selects `WEB_AUTHN` without a window; then, signed out, signs in
    ///      with A again and selects it with window B
    /// - Then:
    ///    - the first sign-in stops on `.continueSignInWithFirstFactorSelection` offering `.webAuthn`
    ///    - the first sheet is made over A, the second over B, and both confirmations are `.done`
    ///    - each selection is `SELECT_CHALLENGE` answered `WEB_AUTHN`, then `WEB_AUTHN` with the credential
    func testTheWebAuthnSelectionUsesTheSignInsWindowUnlessGivenItsOwn() async throws {
        let client = try liveClient()
        let windowA = await WebAuthnFixtures.window()
        let windowB = await WebAuthnFixtures.window()
        let lock = clientHarness.sheetLock
        let holders = TestBox<[SessionID?]>([])
        sheet.answer { [lock] in
            let current = await lock.currentHolder
            holders.with { $0.append(current) }
        }
        harness.scriptIdentityPool()
        harness.scriptSignOut()
        for _ in 0 ..< 2 {
            harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
                InitiateAuthOutput(
                    availableChallenges: [.password, .webAuthn],
                    challengeName: .selectChallenge,
                    challengeParameters: [:],
                    session: "select-session"
                )
            }
            harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
                LiveEngineFixtures.challenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
            }
            harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn("alice") }
        }

        let first = try await client.signIn(username: "alice", presentationAnchor: windowA, options: .init(authFlowType: .userAuth(preferredFirstFactor: nil)))
        let confirmed = try await client.confirmSignIn(challengeResponse: "WEB_AUTHN")
        try await client.signOut()
        _ = try await client.signIn(username: "alice", presentationAnchor: windowA, options: .init(authFlowType: .userAuth(preferredFirstFactor: nil)))
        let own = try await client.confirmSignIn(challengeResponse: "WEB_AUTHN", presentationAnchor: windowB)

        guard case .continueSignInWithFirstFactorSelection(let factors) = first.nextStep else {
            return XCTFail("expected the first-factor selection, got \(first.nextStep)")
        }
        XCTAssertTrue(factors.contains(.webAuthn))
        XCTAssertEqual(confirmed.nextStep, .done)
        XCTAssertEqual(own.nextStep, .done)
        XCTAssertEqual(sheet.ceremonies.count, 2)
        let overA = sheet.ceremonies.first?.anchor === windowA
        let overB = sheet.ceremonies.last?.anchor === windowB
        XCTAssertTrue(overA)
        XCTAssertTrue(overB)
        let respond = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self)
        XCTAssertEqual(respond.map(\.challengeName), [.selectChallenge, .webAuthn, .selectChallenge, .webAuthn])
        XCTAssertEqual(respond.first?.challengeResponses?["ANSWER"], "WEB_AUTHN")
        XCTAssertEqual(holders.value, [work, work])
    }

    /// A user closing the sign-in's sheet ends the sign-in: no attempt is left, and a new sign-in works.
    ///
    /// - Given: Cognito answering a `WEB_AUTHN` challenge, and the sheet answering `.canceled`
    /// - When:
    ///    - alice signs in with the passkey, then answers a challenge, then signs in with her password
    /// - Then:
    ///    - the passkey sign-in throws `.userCancelled` (the `ASAuthorizationError` underneath), never
    ///      `.service`, and the challenge is never answered; the session is signed out with nothing pending
    ///    - the answer throws `.invalidState`: nothing is in progress
    ///    - the password sign-in is `.done`
    func testAUserClosingTheSignInSheetEndsTheSignIn() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        sheet.fail(with: .canceled)
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }

        let cancelled = await authClientError {
            try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)))
        }
        let state = await client.currentSessionState()
        let confirm = await authClientError { try await client.confirmSignIn(challengeResponse: "WEB_AUTHN") }
        let answered = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self)
        try await signIn(client)

        XCTAssertEqual(cancelled?.kind, .userCancelled)
        XCTAssertEqual((cancelled?.underlyingError as? ASAuthorizationError)?.code, .canceled)
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(confirm?.kind, .invalidState)
        XCTAssertEqual(answered.count, 0)
    }

    /// Through the live engine: a sign-out cancels the engine's ceremony, which runs where cancelling
    /// the sign-in's step does not reach.
    ///
    /// - Given: alice signing in with the passkey, her sheet up
    /// - When:
    ///    - the session signs out
    /// - Then:
    ///    - the sheet's ceremony is cancelled (the kept controller's cancel), the sign-in throws the core's
    ///      sign-in-cancelled error, the challenge is never answered, the session is signed out, and the
    ///      lease is free
    func testASignOutCancelsTheEnginesSignInCeremony() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        sheet.answer(with: held.answer)
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }

        let signIn = Task {
            try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)))
        }
        try await held.up()
        try await client.signOut()

        let error = await authClientError { try await signIn.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        await waitUntil("the cancelled ceremony has unwound") { self.sheet.cancelled == 1 }
        await waitUntil("the sheet is free") { await self.clientHarness.sheetLock.currentHolder == nil }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertFalse(harness.cognito.operations.contains("RespondToAuthChallenge"))
    }

    /// The app's sheet tools during a live passkey sign-in: `.userCancelled`, never `.service` (the lease's
    /// `CancellationError` reaches the sign-in through the engine as `WebAuthnError.unknown`, which
    /// `LiveSignInSteps.webAuthnFailure` unwraps).
    ///
    /// - Given: alice signing in with a passkey, her sheet up under the session's lease; twice
    /// - When:
    ///    - the first time `cancelWebUISignIn()` runs; the second time the sheet lock is reset
    /// - Then:
    ///    - both sign-ins throw `passkeySheetClosed()`, a `.userCancelled`; the challenge is never answered, the
    ///      session is signed out with nothing pending, and the sheet is free
    func testTheAppsSheetToolsCloseALivePasskeySignInAsUserCancelled() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        let lock = clientHarness.sheetLock

        for useReset in [false, true] {
            let held = HeldSheet()
            sheet.answer(with: held.answer)
            harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
                LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
            }
            let signIn = Task {
                try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)))
            }
            try await held.up()
            let holder = await lock.currentHolder
            XCTAssertEqual(holder, work)
            if useReset {
                await lock.reset()
            } else {
                await client.cancelWebUISignIn()
            }

            let error = await authClientError { try await signIn.value(within: 10) }
            XCTAssertEqual(error?.kind, .userCancelled, "reset: \(useReset)")
            XCTAssertEqual(error?.errorDescription, SessionCore.passkeySheetClosed().errorDescription)
            await waitUntil("the sheet is free") { await lock.currentHolder == nil }
            let state = await client.currentSessionState()
            XCTAssertEqual(state, .signedOut)
        }
        XCTAssertFalse(harness.cognito.operations.contains("RespondToAuthChallenge"))
    }

    /// The caller cancelling a live passkey sign-in closes its sheet.
    ///
    /// - Given: alice signing in with a passkey, her sheet up
    /// - When:
    ///    - the calling task is cancelled
    /// - Then:
    ///    - the sign-in throws `CancellationError`; the sheet's ceremony was cancelled, the challenge never
    ///      answered, the session signed out, and the sheet free
    func testCancellingALivePasskeySignInClosesItsSheet() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        let held = HeldSheet()
        sheet.answer(with: held.answer)
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }

        let signIn = Task {
            try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)))
        }
        try await held.up()
        signIn.cancel()

        await assertThrowsAsync({ try await signIn.value(within: 10) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await waitUntil("the cancelled ceremony has unwound") { self.sheet.cancelled == 1 }
        await waitUntil("the sheet is free") { await self.clientHarness.sheetLock.currentHolder == nil }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertFalse(harness.cognito.operations.contains("RespondToAuthChallenge"))
    }

    /// A sign-out after the ceremony, while the `WEB_AUTHN` answer is in flight: the tokens Cognito then issues
    /// are revoked once and never committed (`VerifyWebAuthnCredential` goes through the issued-token tap).
    ///
    /// - Given: alice signing in with a passkey; the sheet answered, and `RespondToAuthChallenge` held
    /// - When:
    ///    - the session signs out, then Cognito answers with tokens
    /// - Then:
    ///    - the sign-in throws the sign-in-cancelled `invalidState`; the session is signed out with no record
    ///      holding the tokens; `RevokeToken` ran exactly once, for the issued refresh token
    func testASignOutDuringTheWebAuthnAnswerRevokesTheIssuedTokensOnce() async throws {
        let client = try liveClient()
        let window = await WebAuthnFixtures.window()
        let respond = Gate()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            await respond.pass()
            return LiveEngineFixtures.signedIn("alice")
        }
        harness.scriptSignOut()

        let signIn = Task {
            try await client.signIn(username: "alice", presentationAnchor: window, options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)))
        }
        try await respond.arrivals(1)
        try await client.signOut()
        await respond.open()

        let error = await authClientError { try await signIn.value(within: 10) }
        XCTAssertEqual(error?.errorDescription, SessionCore.signInCancelled().errorDescription)
        await waitUntil("the issued refresh token was revoked") {
            self.harness.cognito.operations.contains("RevokeToken")
        }
        // Give a second revoke, if any, the time to show.
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).map(\.token), ["refresh-alice-v1"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        let record = try clientHarness.storedRecord(work)
        XCTAssertNil(record?.credentials, "the cancelled sign-in's tokens were committed")
        XCTAssertEqual(sheet.ceremonies.count, 1)
    }

    /// A sign-in's window that has gone by its ceremony presents nothing.
    ///
    /// - Given: Cognito answering a `WEB_AUTHN` challenge, and a box whose window has been released
    /// - When:
    ///    - the core signs alice in with the passkey over it
    /// - Then:
    ///    - it throws `.validation(field: "presentationAnchor")`, no sheet is made, the challenge is never
    ///      answered, and nothing is pending
    func testASignInsGoneWindowPresentsNothing() async throws {
        let client = try liveClient()
        let gone = await WebAuthnFixtures.goneWindowBox()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }

        let error = await authClientError {
            try await client.core.signIn(
                username: "alice",
                password: nil,
                options: .init(authFlowType: .userAuth(preferredFirstFactor: .webAuthn)),
                presentationAnchor: gone
            )
        }

        XCTAssertEqual(error?.kind, .validation(field: "presentationAnchor"))
        XCTAssertEqual(sheet.ceremonies.count, 0)
        XCTAssertEqual(harness.cognito.operations, ["InitiateAuth"])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// Only a ceremony takes the sheet: a password sign-in with a window, list and delete never do.
    ///
    /// - Given: a sheet lock that counts every lease it grants
    /// - When:
    ///    - alice signs in with SRP through the anchored overload, lists and deletes her passkeys
    /// - Then:
    ///    - all three succeed, and the lock granted no lease
    func testOnlyACeremonyTakesTheSheet() async throws {
        let grants = TestBox(0)
        let lock = SystemSheetLock(afterAcquire: { _ in grants.with { $0 += 1 } })
        let client = try liveClient(lock: lock)
        let window = await WebAuthnFixtures.window()
        harness.scriptSRP("alice")
        harness.scriptIdentityPool()
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) in ListWebAuthnCredentialsOutput(credentials: []) }
        harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) in DeleteWebAuthnCredentialOutput() }

        let result = try await client.signIn(username: "alice", password: "password", presentationAnchor: window)
        _ = try await client.listWebAuthnCredentials()
        try await client.deleteWebAuthnCredential(credentialId: "cred-1")

        XCTAssertEqual(result.nextStep, .done)
        XCTAssertEqual(grants.value, 0)
        XCTAssertEqual(sheet.ceremonies.count, 0)
    }

    /// An OTP sign-in through the anchored overload, and its confirmation, never take the sheet.
    ///
    /// - Given: a sheet lock that counts every lease it grants, and Cognito answering `EMAIL_OTP`, then tokens
    /// - When:
    ///    - alice signs in with a window and `EMAIL_OTP` preferred, then confirms the code with a window
    /// - Then:
    ///    - the sign-in is `.done`, and the lock granted no lease and no sheet was made
    func testAnOTPStepNeverTakesTheSheet() async throws {
        let grants = TestBox(0)
        let lock = SystemSheetLock(afterAcquire: { _ in grants.with { $0 += 1 } })
        let client = try liveClient(lock: lock)
        let window = await WebAuthnFixtures.window()
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.emailOtp, parameters: [
                "CODE_DELIVERY_DELIVERY_MEDIUM": "EMAIL",
                "CODE_DELIVERY_DESTINATION": "a***@e***"
            ])
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn("alice") }
        harness.scriptIdentityPool()

        let first = try await client.signIn(
            username: "alice",
            presentationAnchor: window,
            options: .init(authFlowType: .userAuth(preferredFirstFactor: .emailOTP))
        )
        let done = try await client.confirmSignIn(challengeResponse: "123456", presentationAnchor: window)

        guard case .confirmSignInWithOTP = first.nextStep else {
            return XCTFail("expected confirmSignInWithOTP, got \(first.nextStep)")
        }
        XCTAssertEqual(done.nextStep, .done)
        XCTAssertEqual(grants.value, 0)
        XCTAssertEqual(sheet.ceremonies.count, 0)
    }

    // MARK: Support

    /// A JSON document, for comparing two encodings whose key order may differ.
    private static func json(_ text: String) throws -> NSDictionary {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? NSDictionary)
    }

    /// A client for `work` over the live engine with the fake sheet, sharing this test's scripted Cognito.
    private func liveClient(lock: SystemSheetLock? = nil) throws -> AmplifyCognitoClient {
        try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: harness.dependencies(clientHarness, sheet: sheet, lock: lock)
        )
    }

    private func signIn(_ client: AmplifyCognitoClient) async throws {
        harness.scriptSRP("alice")
        harness.scriptIdentityPool()
        let result = try await client.signIn(username: "alice", password: "password")
        XCTAssertEqual(result.nextStep, .done)
        harness.cognito.clearCalls()
    }

    /// `InitiateAuth` answers `WEB_AUTHN` with options, `RespondToAuthChallenge` the tokens, and the identity
    /// pool its credentials.
    private func scriptWebAuthnSignIn() {
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in
            LiveEngineFixtures.initiateChallenge(.webAuthn, parameters: ["CREDENTIAL_REQUEST_OPTIONS": WebAuthnFixtures.requestOptions])
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in LiveEngineFixtures.signedIn("alice") }
        harness.scriptIdentityPool()
    }
}

/// An SDK error a `@Sendable` script can throw.
private struct SendableError: @unchecked Sendable {
    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}
#endif
