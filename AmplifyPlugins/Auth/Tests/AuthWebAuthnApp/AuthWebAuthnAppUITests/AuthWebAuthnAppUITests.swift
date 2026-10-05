//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AuthWebAuthnAppUITests: XCTestCase, @unchecked Sendable {
    private let timeout = TimeInterval(30)
    private let app = XCUIApplication()
    private var username: String!
    private var signUpButton: XCUIElement!
    private var associateButton: XCUIElement!
    private var listButton: XCUIElement!
    private var signOutButton: XCUIElement!
    private var signInButton: XCUIElement!
    private var deleteButton: XCUIElement!
    private var deleteUserButton: XCUIElement!
    private var springboard: XCUIApplication!

    private lazy var deviceIdentifier: String = {
        let paths = Bundle.main.bundleURL.pathComponents
        guard let index = paths.firstIndex(where: { $0 == "Devices" }),
              let identifier = paths.dropFirst(index + 1).first
        else {
            fatalError("Failed to get device identifier")
        }

        return identifier
    }()

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        try await bootDevice()
        try await enrollBiometrics()
        if ProcessInfo.processInfo.arguments.contains("GEN2") {
            app.launchArguments.append("GEN2")
        }
        app.launch()
        loadAndValidateElements()
        signUpAndSignInUser()
    }

    @MainActor
    override func tearDown() async throws {
        // A passkey sheet left open keeps its ceremony, and so the app, busy: close it first.
        if springboard != nil {
            for host in sheetHosts {
                let close = host.buttons.matching(
                    NSPredicate(format: "label IN %@", ["close", "Close", "Cancel"])
                ).firstMatch
                // Only a hittable one: tapping anything else fails the test here and would skip the
                // user deletion and uninstall below.
                if close.exists, close.isHittable {
                    close.tap()
                }
            }
        }
        deleteCurrentUser()
        app.terminate()
        username = nil
        signUpButton = nil
        associateButton = nil
        listButton = nil
        signOutButton = nil
        signInButton = nil
        deleteButton = nil
        deleteUserButton = nil
        springboard = nil
        try await uninstallApp()
    }

    /// Because all of the WebAuthn operations are linked and some act as preconditions,
    /// we're testing them all together.
    ///
    /// This includes:
    ///  - A signed in user wants to associate a new WebAuthn credential to their account
    ///  - A signed out user wants to use their associated WebAuthn credentials to sign in
    ///  - A signed in user wants to list their associated WebAuthn credentials
    ///  - A signed in user wants to delete an associated WebAuthn credential
    ///
    @MainActor
    func testWebAuthnAPIs() async throws {
        // 1. Associate new WebAuthn Credential
        let associateDeadline = Date().addingTimeInterval(associateCeremonyWindow)
        guard let associateContinueButton = await passkeySheetButton(
            after: associateButton,
            ceremonyDeadline: associateDeadline
        ) else {
            XCTFail("Failed to find the 'Continue' button to Associate new WebAuthn credential: \(redactedResult)")
            return
        }
        associateContinueButton.tap()

        // Trigger a matching face, again while the ceremony runs
        guard try await waitForResultMatchingBiometrics("WebAuthn credential was associated", until: associateDeadline) else {
            XCTFail("Failed to associate credential: \(redactedResult)")
            return
        }

        // 2. List existing credentials
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 1") else {
            XCTFail("Failed to list credentials: \(redactedResult)")
            return
        }

        // 3. Sign Out
        signOutButton.tap()
        guard waitForResult("User is signed out"), signInButton.exists else {
            XCTFail("Failed to sign out user: \(redactedResult)")
            return
        }

        // 4. Sign in with WebAuthn
        let signInDeadline = Date().addingTimeInterval(signInCeremonyWindow)
        guard let signInContinueButton = await passkeySheetButton(after: signInButton, ceremonyDeadline: signInDeadline) else {
            XCTFail("Failed to find the 'Continue' button to Sign In with WebAuthn: \(redactedResult)")
            return
        }

        // If presented with additional credentials, choose the one for this user by tapping on it
        for host in sheetHosts {
            let webAuthnCredentialButton = host.staticTexts[username]
            if webAuthnCredentialButton.exists {
                webAuthnCredentialButton.tap()
                break
            }
        }

        // Tap the "Continue" button
        signInContinueButton.tap()

        // Trigger a matching face, again while the ceremony runs
        guard try await waitForResultMatchingBiometrics("User is signed in", until: signInDeadline) else {
            XCTFail("Failed to Sign In with WebAuthn: \(redactedResult)")
            return
        }

        // 5. Delete credential
        deleteButton.tap()
        guard waitForResult("WebAuthn credential was deleted") else {
            XCTFail("Failed to delete credential: \(redactedResult)")
            return
        }

        // 6. Verify deletion
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 0") else {
            XCTFail("Failed to list credentials: \(redactedResult)")
            return
        }
    }

    private func bootDevice() async throws {
        try await sendLocalServerRequest(LocalServer.boot(deviceIdentifier), description: "boot the device")
    }

    private func enrollBiometrics() async throws {
        try await sendLocalServerRequest(LocalServer.enroll(deviceIdentifier), description: "enroll biometrics in the device")
    }

    private func matchBiometrics() async throws {
        try await sendLocalServerRequest(LocalServer.match(deviceIdentifier), description: "match biometrics in the device")
    }

    private func uninstallApp() async throws {
        try await sendLocalServerRequest(LocalServer.uninstall(deviceIdentifier), description: "uninstall the App")
    }

    // The local biometrics-control server can be briefly slow/unresponsive; retry instead of
    // failing the whole test on a single -1001 timeout. The server answers within 15 s, with HTTP 500
    // "Timed out …" while its job is still running (or when it stopped a hung one), before this request's
    // 20 s: that is retried too, and a retry waits for the running job instead of starting another.
    private func sendLocalServerRequest(_ server: LocalServer, description: String, attempts: Int = 3) async throws {
        var request = server.urlRequest
        request.timeoutInterval = 20
        var lastError: Error?
        for attempt in 1 ... attempts {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = String(bytes: data, encoding: .utf8) ?? ""
                // The server's answer can name the simulator: it is masked before it is reported.
                let maskedBody = Self.maskingUUIDs(body)
                if status == 500, body.hasPrefix("Timed out") {
                    throw URLError(.timedOut, userInfo: [NSLocalizedDescriptionKey: "The server's \(maskedBody)"])
                }
                XCTAssertTrue(status < 300, "Failed to \(description): HTTP \(status) \(maskedBody)")
                return
            } catch {
                lastError = error
                if attempt < attempts { try? await Task.sleep(nanoseconds: 2_000_000_000) }
            }
        }
        throw try XCTUnwrap(lastError)
    }

    /// `text` with each UUID-shaped string in it, such as the simulator's UDID in the server's answers, replaced
    /// by `<UDID>`: what this test reports goes to CI logs of a public repository.
    private static func maskingUUIDs(_ text: String) -> String {
        text.replacingOccurrences(
            of: "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}",
            with: "<UDID>",
            options: .regularExpression
        )
    }

    @MainActor
    private func loadAndValidateElements() {
        let usernameElement = app.staticTexts["Username"]
        guard usernameElement.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find the Username label")
            return
        }

        username = usernameElement.label.lowercased()

        // Once the Username label exists, all these button are expected to visible as well,
        // so we don't wait for them and instead just check for their existence
        signUpButton = app.buttons["SignUp"]
        guard signUpButton.exists else {
            XCTFail("Failed to find the 'Sign Up and Sign In' button")
            return
        }

        associateButton = app.buttons["AssociateWebAuthn"]
        guard associateButton.exists else {
            XCTFail("Failed to find the 'Associate WebAuthn Credential' button")
            return
        }

        listButton = app.buttons["ListWebAuthn"]
        guard listButton.exists else {
            XCTFail("Failed to find the 'List WebAuthn Credentials' button")
            return
        }

        deleteButton = app.buttons["DeleteWebAuthn"]
        guard deleteButton.exists else {
            XCTFail("Failed to find the 'Delete WebAuthn Credential' button")
            return
        }

        deleteUserButton = app.buttons["DeleteUser"]
        guard deleteUserButton.exists else {
            XCTFail("Failed to find the 'Delete User' button")
            return
        }

        // The Sign In and Sign Out buttons only become visible when Sign Up and Sign In are completed respectively,
        // so we don't check their existance.
        signInButton = app.buttons["SignIn"]
        signOutButton = app.buttons["SignOut"]

        springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    @MainActor
    private func signUpAndSignInUser() {
        signUpButton.tap()
        guard waitForResult("User is signed in"), signOutButton.exists else {
            XCTFail("Failed to Sign Up and Sign In: \(redactedResult)")
            return
        }
    }

    @MainActor
    private func deleteCurrentUser() {
        guard let deleteUserButton else {
            XCTFail("Failed to find the 'Delete User' button")
            return
        }
        deleteUserButton.tap()
        guard waitForResult("User was deleted"), signUpButton.exists else {
            XCTFail("Failed to delete the user: \(redactedResult)")
            return
        }
    }

    @MainActor
    private func waitForResult(_ containing: String, timeout: TimeInterval? = nil) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", containing)
        let element = app.staticTexts.matching(identifier: "LastResult")
            .matching(predicate).firstMatch
        return element.waitForExistence(timeout: timeout ?? self.timeout)
    }

    /// The processes that host the system passkey sheet: SpringBoard before iOS 26,
    /// AuthenticationServicesUI on iOS 26.
    @MainActor
    private var sheetHosts: [XCUIApplication] {
        [springboard, XCUIApplication(bundleIdentifier: "com.apple.AuthenticationServicesUI")]
    }

    /// The time budget, against XCTest's 10-minute execution allowance, counting `setUp()` and `tearDown()`
    /// in it to be safe. Every wait is bounded:
    /// - a simulator-server request: 3 tries of at most 20 s, 2 s apart (64 s), and a request that fails
    ///   all three ends the test (the server answers each try within 15 s, and ends a hung job at 45 s, or
    ///   120 s for `/boot`). A `/match` that times out does not: its ceremony goes on to its window's end
    ///   (`waitForResultMatchingBiometrics`);
    /// - `setUp()`: `/boot` and `/enroll` (about 1 s each), the launch, then 30 s each for the username and
    ///   the sign-up's sign-in, so about 72 s;
    /// - the associate ceremony: `associateCeremonyWindow`, 150 s, plus its last `/match` (about 2 s; up to
    ///   64 s and then a last 4 s for the result when the server times out);
    /// - the sign-in ceremony: `signInCeremonyWindow`, 90 s, plus its last `/match`, as above;
    /// - list, sign out, delete and list again: 30 s each;
    /// - `tearDown()`: closing a sheet (a few queries), 30 s to delete the user, terminating the app, and
    ///   `/uninstall` (64 s), so about 105 s.
    ///
    /// So, with the simulator server answering promptly, a run in which every step passes just inside its
    /// bound and the last fails at it ends within about 72 + 152 + 92 + 120 + 105 = 541 s, and a failing step
    /// ends the test (`continueAfterFailure` is off) and skips the steps after it. With a slow server (each
    /// request near its 64 s bound) the sum can pass 600 s; XCTest's allowance then ends the test, and
    /// `tearDown()`'s delete and uninstall may not run. The XCUI queries have no timeout of their own (the client's harness bounds
    /// them with a deadline that uninstalls the app; this test does not).
    private let associateCeremonyWindow = TimeInterval(150)

    /// Shorter than `associateCeremonyWindow`: the sign-in starts only after the association completed, so
    /// the device has already verified the relying party's association and a `Code=1004` is not expected.
    private let signInCeremonyWindow = TimeInterval(90)

    /// How much of a ceremony's window is kept for its result after the sheet's confirming tap: the sheet
    /// must be found by the window's end minus this.
    private let ceremonyResultTime = TimeInterval(30)

    /// A retry taps this long after the previous try's failure was seen.
    private let ceremonyRetryDelay = TimeInterval(10)

    /// A retry starts only while this much of the sheet's time remains after `ceremonyRetryDelay`, so it can
    /// still wait for its sheet.
    private let ceremonyMinimumTry = TimeInterval(30)

    /// Taps `button` and returns the passkey sheet's confirming button, found before `ceremonyDeadline`
    /// minus `ceremonyResultTime`; nil when there is none by then, or when the ceremony fails with anything
    /// but a transient failure.
    ///
    /// The one transient failure is `Code=1004` in the result line: on a freshly booted simulator a ceremony
    /// fails with it at once, before any sheet, until the device has verified the relying party's association
    /// (the plugin reports "Unable to complete the association"). The client's WebAuthn UI test retries the
    /// same failure; its other retries (a sheet that never appeared, and `browserBusy` right after that) follow
    /// a cancel that this app has no way to make. Every other failure ends the ceremony at once.
    ///
    /// A retry taps `ceremonyRetryDelay` after the failure is seen. Seeing it takes from a moment to 10 s: a
    /// failure that reads the same as the previous one is only told apart from it once the line has blanked
    /// (the app clears it when the action starts) or 10 s have passed. So tries are 10 to 20 s apart, and a new
    /// one starts only while `ceremonyRetryDelay` + `ceremonyMinimumTry` remain for the sheet.
    ///
    /// It taps again only once the previous ceremony has reported its failure, and never after the sheet's
    /// button is returned: tapping while a sheet is still coming up starts a second ceremony, and the first
    /// one then never completes; tapping again under the Face ID prompt hangs.
    @MainActor
    private func passkeySheetButton(after button: XCUIElement, ceremonyDeadline: Date) async -> XCUIElement? {
        let sheetDeadline = ceremonyDeadline.addingTimeInterval(-ceremonyResultTime)
        var attempt = 1
        while true {
            // The previous result (a failure, on a retry) stays up until the app starts the new action:
            // wait for it to change, so it is not read as this attempt's failure.
            let previousResult = lastResult
            button.tap()
            // Nothing to wait for when there was no result: the new one cannot be confused with it.
            let changeDeadline = min(Date().addingTimeInterval(previousResult.isEmpty ? 0 : 10), sheetDeadline)
            while lastResult == previousResult, Date() < changeDeadline {
                pause()
            }
            if let sheetButton = passkeySheetButton(until: sheetDeadline) {
                return sheetButton
            }
            // No failure reported means the ceremony is still running with no sheet found in time: tapping
            // again would stack a second ceremony.
            guard lastResult.contains("Code=1004"),
                  Date().addingTimeInterval(ceremonyRetryDelay + ceremonyMinimumTry) < sheetDeadline
            else {
                return nil
            }
            print("Passkey ceremony try \(attempt): the association is not verified yet (\(redactedResult)); trying again")
            attempt += 1
            try? await Task.sleep(nanoseconds: UInt64(ceremonyRetryDelay * 1_000_000_000))
        }
    }

    /// The passkey sheet's confirming button, by the identifier this test used to query SpringBoard's
    /// `otherElements` for, in any element type, else by its label ("Add Passkey" when saving one on
    /// iOS 26). Waits up to 90 s and not past `deadline`, and returns nil early if the ceremony has already
    /// failed.
    @MainActor
    private func passkeySheetButton(until deadline: Date) -> XCUIElement? {
        let deadline = min(Date().addingTimeInterval(90), deadline)
        let byLabel = NSPredicate(format: "label IN %@", ["Continue", "Add Passkey", "Sign In", "Save Passkey"])
        repeat {
            if lastResult.contains("failed") {
                return nil
            }
            for host in sheetHosts {
                // Hittable, not merely present: a tap while the sheet is still sliding in is lost.
                let byIdentifier = host.descendants(matching: .any)["ASAuthorizationControllerContinueButton"]
                if byIdentifier.exists, byIdentifier.isHittable {
                    return byIdentifier
                }
                let labelled = host.buttons.matching(byLabel).firstMatch
                if labelled.exists, labelled.isHittable {
                    return labelled
                }
            }
            pause()
        } while Date() < deadline
        return nil
    }

    /// Presents a matching face, then waits for the result containing `containing`, presenting the face again
    /// while the action is still running (its result line blank), until `deadline`. The simulator drops a
    /// match that arrives before the Face ID prompt is armed, and the ceremony then waits for a face forever
    /// (as the client's WA-1 found); a match with no prompt up is ignored, so presenting
    /// it again is harmless. A face goes about every 6 s: the server takes about 1.5 s to present one, then
    /// this waits 4 s for the result. The last `/match` can end up to its own bound past `deadline`.
    ///
    /// A `/match` that timed out (the simulator was too busy to run its `simctl spawn` within the server's
    /// limit, as on a loaded CI runner in run 37338053976) does not end the wait while time is left: the result
    /// is checked as after any other, and the next face goes in a new server job. When `deadline` has passed
    /// with a timed-out `/match`, the result gets a last 4 s, and the test fails saying so. Any other failure
    /// of the request throws.
    @MainActor
    private func waitForResultMatchingBiometrics(_ containing: String, until deadline: Date) async throws -> Bool {
        repeat {
            do {
                try await matchBiometrics()
            } catch let error as URLError where error.code == .timedOut {
                guard Date() < deadline else {
                    // The ceremony may still have finished with the face sent before.
                    if waitForResult(containing, timeout: 4) {
                        return true
                    }
                    // The error's text is the server's masked answer (`sendLocalServerRequest`).
                    XCTFail("""
                    The ceremony's window ended with the simulator server's /match timing out, and no \
                    "\(containing)" result: \(redactedResult). \(error.localizedDescription)
                    """)
                    return false
                }
                print("A /match timed out; the face is presented again")
            }
            if waitForResult(containing, timeout: max(0, min(4, deadline.timeIntervalSinceNow))) {
                return true
            }
            guard lastResult.isEmpty else {
                // The action ended with another result: no face will change it.
                return waitForResult(containing, timeout: 1)
            }
        } while Date() < deadline
        return false
    }

    /// The result line with nothing that identifies the run: the action, the error's type, and a platform
    /// code if there is one (as the client's WebAuthn UI test redacts it). The full line can carry the
    /// relying party's domain or a username.
    @MainActor
    private var redactedResult: String {
        let result = lastResult
        if let next = result.range(of: "Next step is: ") {
            // A next step can carry code-delivery details (a masked email or phone number): keep its case only.
            let step = result[next.upperBound...].prefix { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
            return "\(result[..<next.lowerBound])Next step is: \(step)"
        }
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

    /// Half a second, letting the run loop turn (a blocking sleep gets the UI test runner killed). The
    /// sheet's button can exist without being hittable yet, so the loops above must not spin on it.
    @MainActor
    private func pause() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "pause")], timeout: 0.5)
    }

    private var lastResult: String {
        let result = app.staticTexts["LastResult"]
        // SwiftUI drops an empty Text from the hierarchy: no element means the action is still running.
        return result.exists ? result.label : ""
    }
}
