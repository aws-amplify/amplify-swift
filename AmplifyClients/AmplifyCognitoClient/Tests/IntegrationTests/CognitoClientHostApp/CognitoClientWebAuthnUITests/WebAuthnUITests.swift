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

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        device = try SimulatorServer.deviceIdentifier
        try await SimulatorServer.boot(device)
        try await SimulatorServer.enrollBiometrics(device)
        springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    @MainActor
    override func tearDown() async throws {
        // A passkey sheet left open keeps its ceremony, and so the app, busy: close it first.
        for host in sheetHosts ?? [] {
            let close = host.buttons.matching(Self.sheetClose).firstMatch
            if close.exists, close.isHittable {
                close.tap()
            }
        }
        if isSignedUp, let app {
            if cancelInFlightAction() {
                app.buttons["DeleteUser"].tap()
                XCTAssertTrue(waitForResult("User was deleted"), "Failed to delete the user: \(redactedResult)")
            } else {
                // Tapping would be ignored, so the user cannot be deleted from here: that is a failure. P-12
                // (infra/prepare-run.sh) deletes ccit- users older than 24 h.
                XCTFail("Could not delete the user: the app is still busy (\(busyAction)) after cancelling its passkey ceremony")
            }
        }
        app?.terminate()
        app = nil
        confirmedSheet = nil
        springboard = nil
        username = nil
        isSignedUp = false
        if let device {
            // Removes the app. The passkey stays on the simulator; its server-side credential went with
            // step 5 or with the user, so it can no longer sign anyone in.
            try await SimulatorServer.uninstallApp(device)
        }
        device = nil
    }

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
        confirm(associateContinue)
        guard try await waitForResultMatchingBiometrics("WebAuthn credential was associated") else {
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
        app.buttons["SignOut"].tap()
        guard waitForResult("User is signed out"), app.buttons["SignIn"].exists else {
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
        confirm(signInContinue)
        guard try await waitForResultMatchingBiometrics("User is signed in") else {
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

    @MainActor
    private func waitForResult(_ containing: String, timeout: TimeInterval? = nil) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", containing)
        return app.staticTexts.matching(identifier: "LastResult").matching(predicate).firstMatch
            .waitForExistence(timeout: timeout ?? self.timeout)
    }

    /// Presents a matching face, then waits for the result, presenting it again every few seconds while the
    /// ceremony is still running. The simulator drops a match that arrives before the Face ID prompt is
    /// armed, and the ceremony then waits for a face forever (seen in WA-1 runs 1 and 2, 2026-09-26: the
    /// sheet's Continue was tapped, the match was posted, and the delegate never answered). A match with no
    /// prompt up is ignored, so presenting it again is harmless.
    @MainActor
    private func waitForResultMatchingBiometrics(_ containing: String) async throws -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            try await SimulatorServer.matchBiometrics(device)
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

    /// Taps the sheet's confirming button once, and remembers it, so a failure can say whether the sheet
    /// ever took the tap.
    ///
    /// No second tap: tried after review (a re-tap when the button was still hittable 5 s later), it hung the
    /// run. The sheet keeps its button in the hierarchy under the Face ID prompt, still reported hittable, and
    /// the re-tap then waits for SpringBoard to idle while the prompt waits for a face, which only comes after
    /// the tap returns. Presenting the face again (`waitForResultMatchingBiometrics`) is what recovers a
    /// dropped match.
    @MainActor
    private func confirm(_ button: XCUIElement) {
        button.tap()
        confirmedSheet = button
    }

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
    /// probe then cancels its controller, which answers, but the sheet can stay up: seen on 2026-09-27
    /// (`client-final-3x.md`, run 1), where WA-0's warm-up finished with WA-1's passkey offered over the app and
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
