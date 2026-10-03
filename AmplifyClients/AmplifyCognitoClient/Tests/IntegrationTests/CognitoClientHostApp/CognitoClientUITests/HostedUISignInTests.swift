//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import UniformTypeIdentifiers
import XCTest

/// The plugin's `AuthHostedUIAppUITests/HostedUISignInTests`, for the client.
///
/// Both tests drive `CognitoClientHostedUIApp` through the hosted UI of the plugin's hosted-UI backend
/// (`AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json`; on the sandbox, the `default` pool's
/// P-7 domain), with a fresh user each on that backend, and differ only in the window the app passes to
/// `signInWithWebUI`:
///  - HU-1 `testSignInSuccess`: the view's window, as the plugin's test passes its scene's window.
///  - HU-2 `testSignInWithoutPresentationAnchorSuccess`: a window the app looks up itself, the key
///    window of the foreground scene, which is the lookup the plugin's anchor-less call does internally. The
///    client's anchor is not optional, so this is how an app without a view at hand calls it.
///
/// Where the plugin's test signs its user up in the app, these create the user through the API
/// (`SandboxSignUp`) and delete it at teardown (`SandboxUserCleanup`), like every other client suite. Both
/// sign in privately (ephemeral, the client's default; the plugin's app asks `.preferPrivateSession()`),
/// then sign out, which after a private sign-in shows nothing. The logout page of a shared-cookie sign-in is
/// pinned by the live-engine unit tests instead.
///
/// **One browser per test, one test per simulator.** On iOS 26 a simulator presents only its first
/// `ASWebAuthenticationSession`, so each test runs in its own `xcodebuild` invocation on a new simulator
/// (`-only-testing`), as the plugin's CI does. See the README.
///
/// **Credentials are pasted, never typed or printed.** `typeText` records its text in XCTest's activity log
/// (`xcodebuild`'s output and the result bundle), so the user's name and password go into the web form
/// through the simulator's pasteboard: local only, expiring after a minute, and cleared right after the paste
/// and at teardown. A field is checked by its length only. Failure messages carry the app's result line and
/// redacted sheet hierarchies, never a name, password or hosted-UI domain.
final class HostedUISignInTests: XCTestCase, @unchecked Sendable {
    private let timeout = TimeInterval(30)
    private var app: XCUIApplication!

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        // The plugin's `AuthenticatedScreen.signOutIfAuthenticated`: start signed out.
        let state = app.staticTexts["SessionState"]
        guard state.waitForExistence(timeout: timeout) else {
            throw UIStepFailure("The app did not show its session state")
        }
        guard await waitForLabel(of: state, toBeOneOf: ["Signed in", "Signed out"]) else {
            throw UIStepFailure("The app did not read its saved session: \(lastResult)")
        }
        if state.label == "Signed in" {
            try await tapWhenHittable(app.buttons["SignOut"])
            let result = await waitForResult()
            // A leftover's user may be gone already (an earlier teardown deleted it), so its revoke can fail: a
            // `.partial` sign-out still signs it out here. Only `.failed` ("Sign Out failed: …") leaves it signed in.
            guard result.hasPrefix("User is signed out") else {
                throw UIStepFailure("Could not sign the leftover session out: \(result)")
            }
        }
    }

    @MainActor
    override func tearDown() async throws {
        Self.clearPasteboard()
        // For a test that failed before its user existed; otherwise the sign-out teardown block did this.
        await closeSheetsAndCancel()
        app?.terminate()
        app = nil
    }

    /// HU-1. The plugin's `testSignInSuccess`: a hosted-UI sign-in over the view's window.
    ///
    /// - Given: The hosted-UI backend's hosted UI and a fresh, confirmed user created on it through the API
    ///   (`SandboxSignUp`, deleted at teardown)
    /// - When:
    ///    - The app calls `signInWithWebUI(presentationAnchor:)` with its view's window and a private session,
    ///      and the user's name and password are pasted into the hosted UI's form
    /// - Then:
    ///    - The browser returns to the app (the outputs' sign-in redirect, the plugin's `myapp://`), the
    ///      session is signed in and `getCurrentUser` names the user
    ///    - `signOut(presentationAnchor:)` returns `.complete` without showing a browser, and leaves the session
    ///      signed out
    ///
    @MainActor
    func testSignInSuccess() async throws {
        try await signInThroughTheHostedUI(button: "SignIn")
    }

    /// HU-2. The plugin's `testSignInWithoutPresentationAnchorSuccess`: the same, with a window the app looks
    /// up itself (the foreground scene's key window), where the plugin's call looks it up internally.
    ///
    /// - Given: As HU-1, with its own fresh user
    /// - When:
    ///    - The app calls `signInWithWebUI(presentationAnchor:)` with the foreground scene's key window and a
    ///      private session, and the user's name and password are pasted into the hosted UI's form
    /// - Then:
    ///    - As HU-1
    ///
    @MainActor
    func testSignInWithoutPresentationAnchorSuccess() async throws {
        try await signInThroughTheHostedUI(button: "SignInResolvingWindow")
    }

    // MARK: - The flow

    @MainActor
    private func signInThroughTheHostedUI(button: String) async throws {
        guard app.staticTexts["SessionState"].label == "Signed out" else {
            throw UIStepFailure("The app is not signed out at the start: \(lastResult)")
        }
        let user = try await signUpFreshUser(on: .hostedUI)
        // Registered after the user's deletion, so it runs first: a session still signed in is signed out
        // (revoking its tokens) before the user deletes itself.
        addTeardownBlock { @MainActor [weak self] in
            await self?.signOutIfStillSignedIn()
        }
        guard let password = user.password else {
            throw UIStepFailure("The fresh user has no password")
        }

        // 1. Open the hosted UI
        try await tapWhenHittable(app.buttons[button])
        let usernameField = try await hostedUIField(app.webViews.textFields["Username"])

        // 2. Fill the form in and submit it
        try await paste(user.username, into: usernameField, name: "Username")
        try await paste(password, into: app.webViews.secureTextFields["Password"], name: "Password")
        try await tapWhenHittable(app.webViews.buttons["submit"])

        // 3. Signed in, as the user
        let signedIn = await waitForResult(timeout: 60)
        guard signedIn == "User is signed in" else {
            throw UIStepFailure("The hosted-UI sign-in did not complete: \(signedIn)")
        }
        XCTAssertEqual(app.staticTexts["SessionState"].label, "Signed in")
        let currentUser = app.staticTexts["CurrentUser"]
        XCTAssertTrue(currentUser.waitForExistence(timeout: timeout), "The app shows no current user")
        // Compared, never printed.
        XCTAssertTrue(currentUser.label == user.username, "getCurrentUser does not name the user who signed in")

        // 4. Sign out: a private sign-in left no cookie, so no browser is shown
        try await tapWhenHittable(app.buttons["SignOut"])
        let (signedOut, showedBrowser) = await waitForResultWatchingForABrowser()
        XCTAssertEqual(signedOut, "User is signed out", "The sign-out did not complete")
        XCTAssertFalse(showedBrowser, "The sign-out of a private sign-in showed a browser")
        XCTAssertTrue(app.buttons[button].waitForExistence(timeout: timeout), "The app did not return to signed out")
    }

    /// The sign-out teardown block: whatever the test left open is closed, then a session still signed in is
    /// signed out. Best effort; the user is deleted next either way.
    @MainActor
    private func signOutIfStillSignedIn() async {
        await closeSheetsAndCancel()
        guard let app else {
            return
        }
        let signOut = app.buttons["SignOut"]
        if signOut.exists, signOut.isHittable {
            signOut.tap()
            _ = await waitForResult()
        }
    }

    // MARK: - Pasting

    /// Puts `secret` in the form's `field` through the pasteboard: focus (the plugin's two taps for iOS 26),
    /// the edit menu's Paste, then a check of the field's length. The pasteboard holds the secret only
    /// meanwhile, local only (no Universal Clipboard) and expiring after a minute.
    @MainActor
    private func paste(_ secret: String, into field: XCUIElement, name: String) async throws {
        try await focus(field, name: name)
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: secret]],
            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
        )
        defer {
            Self.clearPasteboard()
        }
        try await pasteFromEditMenu(into: field, name: name)
        let deadline = Date().addingTimeInterval(10)
        while (field.value as? String)?.count != secret.count {
            guard Date() < deadline else {
                throw UIStepFailure("The \(name) field does not hold the pasted text's length after the paste")
            }
            _ = field.waitForNonExistence(timeout: 0.5)
        }
    }

    /// Opens the field's edit menu (a long press, then a tap on the focused field if the menu did not come)
    /// and taps Paste, allowing the paste if the system asks.
    @MainActor
    private func pasteFromEditMenu(into field: XCUIElement, name: String) async throws {
        for attempt in 1 ... 3 {
            if attempt == 1 {
                field.press(forDuration: 1.2)
            } else {
                field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            let hosts: [XCUIApplication] = [app] + sheetHosts
            if let paste = await hittableElement(labelled: "Paste", in: hosts, timeout: 5) {
                paste.tap()
                if let allow = await hittableElement(labelled: "Allow Paste", in: hosts, timeout: 2) {
                    allow.tap()
                }
                return
            }
        }
        throw UIStepFailure("The \(name) field's edit menu offered no Paste\n\(sheetHierarchy)")
    }

    /// The first element labelled `label` that is hittable in one of `hosts`, searched in every element type,
    /// within `timeout`.
    @MainActor
    private func hittableElement(labelled label: String, in hosts: [XCUIApplication], timeout: TimeInterval) async -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for host in hosts {
                let element = host.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
                if element.exists, element.isHittable {
                    return element
                }
            }
            // Waits while letting XCTest's run loop turn (a blocking sleep gets the runner killed).
            _ = hosts[0].descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
                .waitForExistence(timeout: 0.5)
        } while Date() < deadline
        return nil
    }

    private static func clearPasteboard() {
        UIPasteboard.general.items = []
    }

    // MARK: - Waiting and tapping

    /// Waits for the hosted UI's form field, clearing a consent sheet if one comes up meanwhile. A private
    /// session asks for no consent, but the plugin's test clears one, and a late one would hide the form.
    @MainActor
    private func hostedUIField(_ element: XCUIElement) async throws -> XCUIElement {
        let deadline = Date().addingTimeInterval(60)
        repeat {
            if element.waitForExistence(timeout: 2) {
                return element
            }
            tapConsentContinueIfPresent()
            if lastResult.contains("failed") {
                break
            }
        } while Date() < deadline
        throw UIStepFailure("The hosted UI's sign-in form did not appear: \(lastResult)\n\(sheetHierarchy)")
    }

    /// Taps a consent sheet's Continue, in SpringBoard or AuthenticationServicesUI (which hosts system
    /// sheets on iOS 26), only once it is hittable.
    @MainActor
    private func tapConsentContinueIfPresent() {
        for host in sheetHosts {
            let element = host.descendants(matching: .any)
                .matching(NSPredicate(format: "label == %@", "Continue"))
                .firstMatch
            if element.exists, element.isHittable {
                element.tap()
                return
            }
        }
    }

    /// iOS 26: the first tap raises the keyboard, the second moves focus to the field (the plugin's
    /// `focusAndType`).
    @MainActor
    private func focus(_ element: XCUIElement, name: String) async throws {
        guard await waitForHittable(element) else {
            throw UIStepFailure("The hosted UI's \(name) field is not hittable")
        }
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
        _ = app.keyboards.element.waitForExistence(timeout: 10)
        coordinate.tap()
    }

    @MainActor
    private func tapWhenHittable(_ element: XCUIElement) async throws {
        guard await waitForHittable(element) else {
            throw UIStepFailure("An element to tap never became hittable: \(lastResult)")
        }
        element.tap()
    }

    @MainActor
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval? = nil) async -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element
        )
        return await XCTWaiter().fulfillment(of: [expectation], timeout: timeout ?? self.timeout) == .completed
    }

    @MainActor
    private func waitForLabel(of element: XCUIElement, toBeOneOf labels: [String]) async -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label IN %@", labels), object: element)
        return await XCTWaiter().fulfillment(of: [expectation], timeout: timeout) == .completed
    }

    /// Waits for the running action's result line and returns it. The app clears the line when an action
    /// starts, so the result read is always this action's own.
    @MainActor
    private func waitForResult(timeout: TimeInterval? = nil) async -> String {
        let result = app.staticTexts["LastResult"]
        // Polled rather than a predicate on `label`: an element whose label is empty can match `label != ''`.
        let deadline = Date().addingTimeInterval(timeout ?? self.timeout)
        while Date() < deadline {
            if result.exists, !result.label.isEmpty {
                return result.label
            }
            _ = result.waitForExistence(timeout: 0.5)
        }
        return lastResult
    }

    /// `waitForResult()`, noting whether a browser (a web view) appeared while the action ran.
    @MainActor
    private func waitForResultWatchingForABrowser() async -> (result: String, showedBrowser: Bool) {
        let result = app.staticTexts["LastResult"]
        var showedBrowser = false
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.webViews.firstMatch.exists {
                showedBrowser = true
            }
            if result.exists, !result.label.isEmpty {
                return (result.label, showedBrowser)
            }
            _ = result.waitForExistence(timeout: 0.5)
        }
        return (lastResult, showedBrowser)
    }

    @MainActor
    private var lastResult: String {
        guard let app else {
            return "(no app)"
        }
        let result = app.staticTexts["LastResult"]
        // SwiftUI drops an empty Text from the hierarchy: no element means the action is still running.
        return result.exists ? result.label : "(no result yet: the action is still running)"
    }

    // MARK: - Sheets

    /// The processes that host system sheets: SpringBoard before iOS 26, AuthenticationServicesUI on it.
    @MainActor
    private var sheetHosts: [XCUIApplication] {
        [
            XCUIApplication(bundleIdentifier: "com.apple.springboard"),
            XCUIApplication(bundleIdentifier: "com.apple.AuthenticationServicesUI"),
        ]
    }

    /// Closes a browser or consent sheet left open, tapping only a hittable Cancel or Close in any element
    /// type, then cancels an action still running, so the app is idle.
    @MainActor
    private func closeSheetsAndCancel() async {
        let close = NSPredicate(format: "identifier == 'Close' OR label == 'Close' OR label == 'Cancel'")
        var hosts = sheetHosts
        if let app {
            hosts.insert(app, at: 0)
        }
        for host in hosts {
            let button = host.descendants(matching: .any).matching(close).firstMatch
            if button.exists, button.isHittable {
                button.tap()
            }
        }
        if let app, app.staticTexts["Busy"].exists {
            let cancel = app.buttons["CancelWebUI"]
            if cancel.exists, cancel.isHittable {
                cancel.tap()
            }
            _ = app.staticTexts["Busy"].waitForNonExistence(timeout: 10)
        }
    }

    /// What the sheet hosts show, for a failure message, redacted: the hosted-UI domain, pool and client IDs,
    /// UUIDs, URLs, and test users' names and addresses are replaced, as `redact` in `infra/lib.sh` does. The
    /// app's own hierarchy is left out: it holds the form.
    @MainActor
    private var sheetHierarchy: String {
        Self.redacted(sheetHosts.map(\.debugDescription).joined(separator: "\n"))
    }

    static func redacted(_ text: String) -> String {
        let rules: [(String, String)] = [
            (#"[a-z0-9-]+\.auth\.[a-z0-9-]+\.amazoncognito\.com"#, "<hosted-ui-domain>"),
            (#"https?://[^\s'"]+"#, "<url>"),
            (#"[a-z]{2}-[a-z]+-[0-9]:[0-9a-f-]{36}"#, "<identity-pool>"),
            (#"[a-z]{2}-[a-z]+-[0-9]_[A-Za-z0-9]{6,}"#, "<user-pool>"),
            (#"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"#, "<id>"),
            (#"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+"#, "<email>"),
            (#"(?i)ccit-[a-z0-9-]+"#, "<user>"),
            (#"(^|[^a-z0-9])[a-z0-9]{26}([^a-z0-9]|$)"#, "$1<id>$2"),
        ]
        var text = text
        for (pattern, template) in rules {
            text = text.replacingOccurrences(of: pattern, with: template, options: .regularExpression)
        }
        return text
    }
}

/// A step that cannot go on: thrown, so the first failure ends the test.
struct UIStepFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
