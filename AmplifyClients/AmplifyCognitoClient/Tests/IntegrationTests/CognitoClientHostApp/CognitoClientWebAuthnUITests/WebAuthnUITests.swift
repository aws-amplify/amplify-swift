//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

/// The plugin's `AuthWebAuthnAppUITests.testWebAuthnAPIs`, for the client.
///
/// Both tests drive the same screen through the same steps as the plugin's test: the passkey sheet in
/// SpringBoard, Face ID through the simulator server, and the result line. They differ only in the
/// driver the app is launched with:
///  - WA-0 `testWebAuthnFlowOverTheRawCognitoAPI` (always compiled): the raw Cognito API. It proves the
///    sandbox's relying party, this app's association with it, and the simulator's biometrics now.
///  - WA-1 `testWebAuthnAPIs` (compiled with `COGNITO_CLIENT_WEBAUTHN_API`, which
///    `CognitoClientWebAuthn.xcconfig` turns on): the client's WebAuthn API.
///
/// Needs: the plugin's WebAuthn backend (`AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json`; on the
/// sandbox, U-WA, with `WEB_AUTHN` and the relying party, P-10), and the plugin's simulator server running on
/// the host (`SimulatorServer`).
final class WebAuthnUITests: XCTestCase, @unchecked Sendable {
    private let timeout = TimeInterval(30)
    private var app: XCUIApplication!
    private var springboard: XCUIApplication!
    private var device: String!
    private var username: String!
    /// Set once the user exists; tearDown deletes it (signing in with the password if need be).
    private var isSignedUp = false
    /// The passkey sheet's confirming button, once tapped.
    private var confirmedSheet: XCUIElement?
    /// The teardown's deadline, held on the test so that tearDown awaits and ends it before the test finishes.
    private var teardownDeadline: StepDeadline?

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        device = try SimulatorServer.deviceIdentifier
        try await SimulatorServer.boot(device)
        try await SimulatorServer.enrollBiometrics(device)
        springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    /// Every wait is bounded: the simulator server's requests by their own timeout (`SimulatorServer.post`),
    /// and each XCUI call, which blocks the main thread until the app and the sheet's host idle and has no
    /// timeout of its own, by a `StepDeadline`. In a live run, WA-1's sheet stayed up after its confirming tap
    /// on a fresh simulator, and this teardown then held the runner about 8 minutes, until XCTest's 10-minute
    /// allowance, without ever sending its `/uninstall`.
    ///
    /// The time budget, against that 10-minute allowance. A passing WA-1 takes 62 to 95 s. A failing step ends
    /// the flow (`continueAfterFailure` is off), so a failing run is the steps before it at their usual pace,
    /// the failing step at its bound, and this teardown. The longest bounds are the warm-up (130 s, then 10 s
    /// for the busy flag and up to 30 s for a sheet it left), a sheet that never appears (`attemptSheet`: tries
    /// start only within `sheetRetryLimit`, 120 s, and each waits `timeout`, 30 s, so about 160 s), and the
    /// first ceremony's result (`firstCeremonyTimeout`, 60 s, plus up to 64 s for a `/match` the server does not
    /// answer). The teardown is at most 30 s (the sheet), 60 s (the user), 30 s (terminating) and 64 s (the
    /// uninstall: 3 tries of 20 s, 2 s apart), about 3 minutes. So a run with one step failing at its bound
    /// ends within about 6 minutes; setUp's `/boot` and `/enroll` add at most 64 s each if the server stalls.
    @MainActor
    override func tearDown() async throws {
        // A failure here must not stop the teardown before its uninstall.
        continueAfterFailure = true
        teardownDeadline?.end()
        let deadline = device.map(StepDeadline.init(device:))
        teardownDeadline = deadline
        // A passkey sheet left open keeps its ceremony, and so the app, busy: close it first.
        deadline?.begin("Closing the passkey sheet", limit: Self.teardownStepLimit)
        for host in sheetHosts ?? [] {
            let close = host.buttons.matching(Self.sheetClose).firstMatch
            if close.exists, close.isHittable {
                close.tap()
                if !close.waitForNonExistence(timeout: 5) {
                    XCTContext.runActivity(named: "The passkey sheet stayed up 5 s after its Close was tapped") { _ in }
                }
            }
        }
        if isSignedUp, let app {
            if deadline?.hasExpired == true {
                // The deadline sent the app's uninstall: there is no app left to delete the user with. P-12
                // (infra/prepare-run.sh) deletes ccit- users older than 24 h.
                XCTFail("Could not delete the user: the app was uninstalled to end a stuck teardown step")
            } else {
                deadline?.begin("Deleting the user", limit: Self.teardownStepLimit + timeout)
                if cancelInFlightAction() {
                    app.buttons["DeleteUser"].tap()
                    XCTAssertTrue(waitForResult("User was deleted"), "Failed to delete the user: \(redactedResult)")
                } else {
                    // Tapping would be ignored, so the user cannot be deleted from here: that is a failure. P-12
                    // deletes it.
                    XCTFail("Could not delete the user: the app is still busy (\(busyAction)) after cancelling its passkey ceremony")
                }
            }
        }
        if deadline?.hasExpired != true {
            deadline?.begin("Terminating the app", limit: Self.teardownStepLimit)
            app?.terminate()
        }
        deadline?.end()
        app = nil
        confirmedSheet = nil
        springboard = nil
        username = nil
        isSignedUp = false
        // The uninstall a deadline sent belongs to this test: it ends here, not during the next one.
        await deadline?.waitForUninstall()
        var uninstallError: Error?
        if let device, deadline?.uninstalledApp != true {
            // Removes the app, unless a deadline's uninstall already did. The passkey stays on the simulator; its
            // server-side credential went with step 5 or with the user, so it can no longer sign anyone in.
            do {
                try await SimulatorServer.uninstallApp(device)
            } catch {
                uninstallError = error
            }
        }
        device = nil
        for step in deadline?.timedOut ?? [] {
            XCTFail("Teardown: \(step)")
        }
        teardownDeadline = nil
        if let uninstallError {
            throw uninstallError
        }
    }

    /// How long a teardown step (closing the sheet, terminating the app) may take before its `StepDeadline`
    /// uninstalls the app. Deleting the user gets `timeout` more, for its result.
    private static let teardownStepLimit: TimeInterval = 30

    /// WA-0. The plugin's WebAuthn flow over the raw Cognito API.
    ///
    /// - Given: The WebAuthn pool (U-WA) with `WEB_AUTHN` and the plugin's relying party, this app signed
    ///   with an app ID that relying party's apple-app-site-association lists, and Face ID enrolled
    /// - When:
    ///    - A fresh user signs up and signs in with a password, associates a passkey (sheet, Face ID),
    ///      lists, signs out, signs in with the passkey (sheet, Face ID), deletes the passkey and lists
    ///      again, all through `StartWebAuthnRegistration`, `CompleteWebAuthnRegistration`,
    ///      `ListWebAuthnCredentials`, `InitiateAuth` `USER_AUTH` + `RespondToAuthChallenge` `WEB_AUTHN`
    ///      and `DeleteWebAuthnCredential`
    /// - Then:
    ///    - Every step reports success, the list has 1 credential after associating and 0 after deleting
    ///
    @MainActor
    func testWebAuthnFlowOverTheRawCognitoAPI() async throws {
        try await runWebAuthnFlow(driver: "raw")
    }

    #if COGNITO_CLIENT_WEBAUTHN_API
    /// WA-1. The plugin's `testWebAuthnAPIs`, through the client's WebAuthn API.
    ///
    /// - Given: As WA-0
    /// - When:
    ///    - The same steps, through `AmplifyCognitoClient`: `signIn` (`.userPassword`, then
    ///      `.userAuth(preferredFirstFactor: .webAuthn)` with a presentation anchor),
    ///      `associateWebAuthnCredential(presentationAnchor:)`, `listWebAuthnCredentials()`,
    ///      `deleteWebAuthnCredential(credentialId:)`, `signOut()` and `deleteUser()`
    /// - Then:
    ///    - As WA-0
    ///
    @MainActor
    func testWebAuthnAPIs() async throws {
        try await runWebAuthnFlow(driver: "client")
    }
    #endif

    // MARK: - The plugin's flow

    /// Because all of the WebAuthn operations are linked and some act as preconditions, they are tested
    /// together, as the plugin does.
    @MainActor
    private func runWebAuthnFlow(driver: String) async throws {
        launch(driver: driver)
        try warmUp()

        // 0. Sign up and sign in with a password
        app.buttons["SignUp"].tap()
        let signedIn = waitForResult("User is signed in")
        // The raw SignUp succeeded (the app says so) even if the sign-in then failed: teardown deletes the user.
        isSignedUp = app.staticTexts["SignedUp"].exists
        guard signedIn, app.buttons["SignOut"].exists else {
            XCTFail("Failed to Sign Up and Sign In: \(redactedResult)")
            return
        }

        // 1. Associate a new WebAuthn credential
        let associateSheet = await attemptSheet {
            app.buttons["AssociateWebAuthn"].tap()
        }
        guard let associateContinue = associateSheet else {
            XCTFail("Failed to find the passkey sheet's button to associate a WebAuthn credential: \(redactedResult)")
            return
        }
        // The flow's first sheet: on a fresh simulator it is the first one AuthenticationServicesUI shows after
        // the install, which is slow (`firstCeremonyTimeout`).
        guard try await confirm(associateContinue, waitingFor: "WebAuthn credential was associated", timeout: Self.firstCeremonyTimeout) else {
            XCTFail("Failed to associate credential: \(redactedResult); \(sheetState)")
            return
        }

        // 2. List existing credentials
        app.buttons["ListWebAuthn"].tap()
        guard waitForResult("WebAuthn Credentials: 1") else {
            XCTFail("Failed to list credentials: \(redactedResult)")
            return
        }

        // 3. Sign out
        // Exactly: a `.partial` sign-out ("User is signed out, but part of it failed: …") must fail the flow.
        app.buttons["SignOut"].tap()
        guard waitForResult("User is signed out", exactly: true), app.buttons["SignIn"].exists else {
            XCTFail("Failed to sign out user: \(redactedResult)")
            return
        }

        // 4. Sign in with the passkey
        let signInSheet = await attemptSheet {
            app.buttons["SignIn"].tap()
        }
        guard let signInContinue = signInSheet else {
            XCTFail("Failed to find the passkey sheet's button to sign in with WebAuthn: \(redactedResult)")
            return
        }
        // If the sheet offers more than one passkey, pick this user's
        for host in sheetHosts {
            let credential = host.staticTexts[username]
            if credential.waitForExistence(timeout: 1) {
                credential.tap()
                break
            }
        }
        guard try await confirm(signInContinue, waitingFor: "User is signed in", timeout: timeout) else {
            XCTFail("Failed to sign in with WebAuthn: \(redactedResult); \(sheetState)")
            return
        }

        // 5. Delete the credential
        app.buttons["DeleteWebAuthn"].tap()
        guard waitForResult("WebAuthn credential was deleted") else {
            XCTFail("Failed to delete credential: \(redactedResult)")
            return
        }

        // 6. Verify the deletion
        app.buttons["ListWebAuthn"].tap()
        guard waitForResult("WebAuthn Credentials: 0") else {
            XCTFail("Failed to list credentials: \(redactedResult)")
            return
        }
    }

    @MainActor
    private func launch(driver: String) {
        app = XCUIApplication()
        app.launchArguments += ["-WebAuthnDriver", driver]
        app.launch()
        let usernameLabel = app.staticTexts["Username"]
        guard usernameLabel.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find the Username label")
            return
        }
        username = usernameLabel.label
        for button in ["SignUp", "AssociateWebAuthn", "ListWebAuthn", "DeleteWebAuthn", "DeleteUser"] {
            XCTAssertTrue(app.buttons[button].exists, "Failed to find the '\(button)' button")
        }
    }

    /// Waits for the result line to contain `containing`, or, with `exactly`, to be exactly it.
    @MainActor
    private func waitForResult(_ containing: String, exactly: Bool = false, timeout: TimeInterval? = nil) -> Bool {
        let predicate = NSPredicate(format: exactly ? "label == %@" : "label CONTAINS %@", containing)
        return app.staticTexts.matching(identifier: "LastResult").matching(predicate).firstMatch
            .waitForExistence(timeout: timeout ?? self.timeout)
    }

    /// Presents a matching face, then waits for the result, presenting it again every few seconds while the
    /// ceremony is still running. The simulator drops a match that arrives before the Face ID prompt is
    /// armed, and the ceremony then waits for a face forever (seen in WA-1 runs 1 and 2, 2026-09-26: the
    /// sheet's Continue was tapped, the match was posted, and the delegate never answered). A match with no
    /// prompt up is ignored, so presenting it again is harmless.
    ///
    /// A `/match` that timed out (the simulator was too busy to run its `simctl spawn` within the server's
    /// limit, as on a loaded CI runner in run 37338053976) does not end the wait while time is left: the result
    /// is checked as after any other, and the next face goes in a new server job. When the window has ended
    /// with a timed-out `/match`, the result gets a last 4 s, and the step fails saying so. A `/match` the
    /// server refused throws.
    @MainActor
    private func waitForResultMatchingBiometrics(_ containing: String, timeout: TimeInterval) async throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            do {
                try await SimulatorServer.matchBiometrics(device)
            } catch let error as SimulatorServerError where error.isTimeout {
                guard Date() < deadline else {
                    // The ceremony may still have finished with the face sent before.
                    if waitForResult(containing, timeout: 4) {
                        return true
                    }
                    XCTFail("""
                    The ceremony's \(Int(timeout)) s ended with the simulator server's /match timing out, and no \
                    "\(containing)" result: \(redactedResult). \(error)
                    """)
                    return false
                }
                XCTContext.runActivity(named: "A /match timed out; the face is presented again") { _ in }
            }
            if waitForResult(containing, timeout: 4) {
                return true
            }
            guard app.staticTexts["Busy"].exists else {
                // The action ended with another result: no face will change it.
                return waitForResult(containing, timeout: 1)
            }
        } while Date() < deadline
        return false
    }

    /// Taps until the passkey sheet shows its confirming button, retrying only what a fresh simulator does:
    /// - the relying party's association not verified yet (`Code=1004` in the result line);
    /// - a sheet that never appeared while the action is still running: the action is cancelled first;
    /// - `browserBusy`, but only on the try after such a cancel, whose sheet may still be closing. A
    ///   `browserBusy` with no cancel before it means a lease leaked, which must fail the test.
    ///
    /// At most `sheetAttempts` tries, 10 s apart, and never one that could end past `sheetRetryLimit`: a try
    /// takes up to `timeout` (30 s) waiting for the sheet, then 10 s before the next, so a new try starts only
    /// while 40 s remain. Each retry and its reason is recorded in the test report. Any other outcome ends the
    /// attempts at once.
    @MainActor
    private func attemptSheet(_ tap: () -> Void) async -> XCUIElement? {
        let deadline = Date().addingTimeInterval(Self.sheetRetryLimit)
        var cancelledBefore = false
        for attempt in 1 ... Self.sheetAttempts {
            tap()
            if let button = passkeySheetButton() {
                return button
            }
            let reason: String
            if app.staticTexts["Busy"].exists {
                guard cancelInFlightAction() else {
                    return nil
                }
                reason = "no sheet appeared; the action was cancelled"
                cancelledBefore = true
            } else if lastResult.contains("Code=1004") {
                reason = "the association was not verified yet (1004)"
                cancelledBefore = false
            } else if cancelledBefore, lastResult.contains("browserBusy") {
                reason = "the cancelled action's sheet was still closing (browserBusy)"
                cancelledBefore = false
            } else {
                return nil
            }
            guard Date().addingTimeInterval(timeout + 10) < deadline else {
                return nil
            }
            XCTContext.runActivity(named: "Retry \(attempt) of the passkey sheet: \(reason)") { _ in }
            try? await Task.sleep(nanoseconds: 10_000_000_000)
        }
        return nil
    }

    private static let sheetAttempts = 6
    private static let sheetRetryLimit: TimeInterval = 120

    /// The result line with nothing that identifies the run: the action, the error's case, and a platform code
    /// if there is one. The full line can carry the app's team and bundle ID, the relying party's domain, a
    /// session ID or a username.
    @MainActor
    private var redactedResult: String {
        let result = lastResult
        guard let failed = result.range(of: " failed: ") else {
            // Success lines and the no-result placeholder carry no identifier.
            return result
        }
        let action = result[..<failed.lowerBound]
        let rest = result[failed.upperBound...]
        let head = rest.prefix { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
        let code = rest.range(of: #"Code=-?[0-9]+"#, options: .regularExpression).map { " (\(rest[$0]))" } ?? ""
        return "\(action) failed: \(head)\(code)"
    }

    /// Taps the sheet's confirming button once, remembers it (so a failure can say whether the sheet ever took
    /// the tap, `sheetState`), and waits up to `timeout` for the result containing `containing`, presenting a
    /// matching face about every 4 to 7 s (`waitForResultMatchingBiometrics`: one `/match`, then a 4 s wait for
    /// the result, then a check of the busy flag). Presenting the face again is what recovers a dropped match.
    ///
    /// No second tap, for a sheet still up after the first (WA-1 in a live run, on a fresh simulator) or for any
    /// other reason. A re-tap was tried earlier and hung the run: the sheet keeps its
    /// button in the hierarchy under the Face ID prompt, still reported hittable, and the re-tap waited for the
    /// sheet's host to idle while the prompt waited for a face that only came after the tap returned. Nothing the
    /// harness can query tells a sheet that ignored its tap from one with the Face ID prompt up under it (the
    /// plugin's `AuthWebAuthnAppUITests` has no such query either), so a still-hittable button proves nothing,
    /// and the step fails instead, saying the sheet is still up (`sheetState`). Its teardown is bounded
    /// (`tearDown()`).
    @MainActor
    private func confirm(_ button: XCUIElement, waitingFor containing: String, timeout: TimeInterval) async throws -> Bool {
        button.tap()
        confirmedSheet = button
        return try await waitForResultMatchingBiometrics(containing, timeout: timeout)
    }

    /// How long the flow's first ceremony (associating the passkey) is given for its result after the sheet's
    /// confirming tap, instead of `timeout`. Only the first: on a fresh simulator the warm-up shows no sheet
    /// (the simulator holds no passkey for the relying party), so the associate sheet is the first one
    /// AuthenticationServicesUI shows after the install, and its confirming tap has taken 10 s to be delivered,
    /// with one accessibility snapshot taking 46 s. Later ceremonies keep `timeout`.
    private static let firstCeremonyTimeout: TimeInterval = 60

    /// The sheet button last confirmed, and whether it is gone: part of a failure message.
    @MainActor
    private var sheetState: String {
        guard let confirmedSheet else {
            return "no sheet was confirmed"
        }
        return confirmedSheet.exists ? "the sheet is still up after its confirming tap" : "the sheet has closed"
    }

    /// Runs the app's association warm-up (`AssociationWarmUp`) after every launch. Every test reinstalls the app
    /// (its teardown uninstalls it), and a reinstalled app's association is verified again: on an erased
    /// simulator, a second test that skipped the warm-up met 1004 on its first ceremony. Once verified, the
    /// warm-up takes one probe and shows nothing.
    @MainActor
    private func warmUp() throws {
        app.buttons["WarmUp"].tap()
        let finished = NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "Warm-up finished", "Warm Up failed")
        guard app.staticTexts.matching(identifier: "LastResult").matching(finished).firstMatch.waitForExistence(timeout: 130) else {
            XCTFail("The association warm-up did not finish: \(redactedResult)")
            return
        }
        guard lastResult.contains("Warm-up finished") else {
            XCTFail("The association warm-up failed: \(redactedResult)")
            return
        }
        // "Warm-up finished after N probes": more than one probe means it met 1004.
        XCTContext.runActivity(named: lastResult) { _ in }
        // The flow's first tap must not land while the app is still busy, which ignores it (the result line and
        // the busy flag change in one main-actor turn, so this is a guard).
        guard app.staticTexts["Busy"].waitForNonExistence(timeout: 10) else {
            XCTFail("The app stayed busy after the warm-up")
            return
        }
        // Nor while a probe's sheet is still over the app, which swallows it.
        guard closeLeftoverSheet() else {
            XCTFail("A passkey sheet the warm-up opened stayed up after its Close was tapped")
            return
        }
    }

    /// Closes a passkey sheet a warm-up probe left open. Returns whether none is left.
    ///
    /// A probe shows a sheet when the simulator holds a passkey for the relying party, as it does after the
    /// other test of this class ran first on it (its passkey stays in the simulator's Passwords store). The
    /// probe then cancels its controller, which answers, but the sheet can stay up: seen on 2026-09-27,
    /// where WA-0's warm-up finished with WA-1's passkey offered over the app and
    /// the flow's first tap landed on the sheet's dimming, not on the app. A sheet can also still be on its way
    /// in when the warm-up returns, so this looks for 2 s before deciding there is none.
    @MainActor
    private func closeLeftoverSheet() -> Bool {
        let settle = Date().addingTimeInterval(2)
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            guard let close = sheetCloseButton() else {
                if Date() >= settle {
                    return true
                }
                // Lets XCTest's run loop turn while waiting (a blocking sleep gets the runner killed).
                _ = sheetHosts[0].buttons.matching(Self.sheetClose).firstMatch.waitForExistence(timeout: 0.5)
                continue
            }
            XCTContext.runActivity(named: "Closed a passkey sheet the warm-up left open") { _ in }
            close.tap()
            _ = close.waitForNonExistence(timeout: 5)
        } while Date() < deadline
        return sheetCloseButton() == nil
    }

    /// The Close (or Cancel) button of a passkey sheet that is up, in either host.
    @MainActor
    private func sheetCloseButton() -> XCUIElement? {
        for host in sheetHosts ?? [] {
            let close = host.buttons.matching(Self.sheetClose).firstMatch
            if close.exists, close.isHittable {
                return close
            }
        }
        return nil
    }

    /// A passkey sheet's close button: the plugin's test's labels, or the identifier.
    private static var sheetClose: NSPredicate {
        NSPredicate(format: "identifier == 'Close' OR label IN %@", ["close", "Close", "Cancel"])
    }

    /// Cancels the app's running action, if any, and waits for it to end. Returns whether the app is idle.
    @MainActor
    private func cancelInFlightAction() -> Bool {
        let busy = app.staticTexts["Busy"]
        guard busy.exists else {
            return true
        }
        app.buttons["CancelCeremony"].tap()
        return busy.waitForNonExistence(timeout: 10)
    }

    @MainActor
    private var busyAction: String {
        let busy = app.staticTexts["Busy"]
        return busy.exists ? busy.label : "not busy"
    }

    @MainActor
    private var lastResult: String {
        let result = app.staticTexts["LastResult"]
        // SwiftUI drops an empty Text from the hierarchy: no element means the action is still running.
        return result.exists ? result.label : "(no result yet: the action is still running)"
    }

    /// The processes that host the system passkey sheet. SpringBoard did before iOS 26, the plugin's
    /// test looks there; on iOS 26 the sheet belongs to AuthenticationServicesUI.
    @MainActor
    private var sheetHosts: [XCUIApplication]! {
        guard springboard != nil else {
            return nil
        }
        return [springboard, XCUIApplication(bundleIdentifier: "com.apple.AuthenticationServicesUI")]
    }

    /// The passkey sheet's confirming button ("Continue", or "Add Passkey" when saving one on iOS 26),
    /// found by the identifier the plugin's test uses, else by its label, in any element type, and only once
    /// it can be tapped. `nil` as soon as the action reports a failure.
    @MainActor
    private func passkeySheetButton() -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        let byLabel = NSPredicate(format: "label IN %@", ["Continue", "Add Passkey", "Sign In", "Save Passkey"])
        repeat {
            // The action already failed: no sheet is coming (the plugin's test stops here too).
            if lastResult.contains("failed") {
                return nil
            }
            for host in sheetHosts {
                let byIdentifier = host.descendants(matching: .any)["ASAuthorizationControllerContinueButton"]
                if byIdentifier.exists, byIdentifier.isHittable {
                    return byIdentifier
                }
                let labelled = host.buttons.matching(byLabel).firstMatch
                if labelled.exists, labelled.isHittable {
                    return labelled
                }
            }
            // Waits while letting XCTest's run loop turn (a blocking sleep gets the runner killed).
            _ = sheetHosts[0].descendants(matching: .any)["ASAuthorizationControllerContinueButton"].waitForExistence(timeout: 1)
        } while Date() < deadline
        return nil
    }
}

/// Bounds a step XCTest cannot: an XCUI call (a tap, `terminate()`) blocks the main thread until the app and
/// the passkey sheet's host idle, and has no timeout of its own, so a stalled sheet can hold the runner until
/// XCTest's execution-time allowance (WA-1, in a live run: about 8 minutes, in teardown).
///
/// `begin(_:limit:)` starts a step, ending the one before it. A step still running at its limit has the
/// simulator server uninstall the app, from a task off the main actor: that ends the app's ceremony, which
/// closes its sheet and releases the blocked call. The step is then listed in `timedOut`, for the test to
/// fail with, and printed at once, in case the call never returns. The test awaits that uninstall
/// (`waitForUninstall()`) before it ends, so it cannot land in the next test.
final class StepDeadline: @unchecked Sendable {
    private let device: String
    private let lock = NSLock()
    private var timer: Task<Void, Never>?
    private var uninstall: Task<Void, Never>?
    private var expired: [String] = []
    private var fired = false
    private var uninstalled = false

    init(device: String) {
        self.device = device
    }

    /// Starts `step`, which must end within `limit` seconds, and ends the step before it. Once a step has run
    /// past its limit, no later step is timed: the app's uninstall has been sent, and there is nothing left to
    /// end.
    func begin(_ step: String, limit: TimeInterval) {
        end()
        guard !hasExpired else {
            return
        }
        let timer = Task.detached { [self] in
            guard (try? await Task.sleep(nanoseconds: UInt64(limit * 1_000_000_000))) != nil else {
                return
            }
            expire(step, limit: limit)
        }
        lock.withLock {
            self.timer = timer
        }
    }

    /// Ends the current step. An uninstall already sent goes on (`waitForUninstall()`).
    func end() {
        lock.withLock {
            timer?.cancel()
            timer = nil
        }
    }

    /// The steps that ran past their limit, each with what was done about it.
    var timedOut: [String] {
        lock.withLock { expired }
    }

    /// Whether a step ran past its limit, so the app's uninstall was sent.
    var hasExpired: Bool {
        lock.withLock { fired }
    }

    /// Whether the uninstall a step's deadline sent succeeded.
    var uninstalledApp: Bool {
        lock.withLock { uninstalled }
    }

    /// Returns once the uninstall a step's deadline sent, if any, has ended (it is bounded by
    /// `SimulatorServer.post`).
    func waitForUninstall() async {
        let uninstall = lock.withLock { self.uninstall }
        await uninstall?.value
    }

    /// Records the step first, so the call it releases finds it, then sends the uninstall from a task of its
    /// own, which ending the step does not cancel.
    private func expire(_ step: String, limit: TimeInterval) {
        let message = "\(step) did not finish within \(Int(limit)) s; the app's uninstall was sent to end it"
        let uninstall = Task.detached { [self] in
            do {
                try await SimulatorServer.uninstallApp(device)
                lock.withLock { uninstalled = true }
            } catch {
                lock.withLock { expired.append("The uninstall sent to end a stuck step failed: \(error)") }
            }
        }
        lock.withLock {
            fired = true
            expired.append(message)
            self.uninstall = uninstall
        }
        print("[WebAuthnUITests] \(message).")
    }
}
