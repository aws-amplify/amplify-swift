//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

struct SignInScreen: Screen {

    let app: XCUIApplication
    /// The sign-in button last tapped, to tap again when the tap is lost.
    var tappedSignInButton: String?
    /// When that button was tapped, so a tap again waits 10 s from the tap, not from the wait.
    var signInTappedAt: Date?

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    private enum Identifiers {
        static let signUpNav = "hostedUI_signUp_view_nav"
        static let signInButton = "hostedUI_signIn_button"
        static let signInWithoutWindowButton = "hostedUI_signIn_wo_window_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
        static let signInStartedLabel = "hostedUI_signIn_started_text"
    }

    func gotoSignUpView() -> SignUpScreen {
        let signUpLink = app.buttons[Identifiers.signUpNav]
        XCTAssertTrue(signUpLink.waitForExistence(timeout: UITestTimeout.firstLoad), "Sign up link not found")
        let signUpScreen = SignUpScreen(app: app)
        // On a loaded runner a tap on the link can be lost, leaving the signed-out screen up, and
        // the sign-up screen then never shows. Tap again while the link is still on screen; once the
        // link is gone the push happened and only the wait goes on. Ends when the screen shows.
        var taps = 0
        let deadline = Date().addingTimeInterval(60)
        repeat {
            if signUpLink.exists, signUpLink.isHittable {
                signUpLink.tap()
                taps += 1
            }
            if signUpScreen.waitUntilShown(timeout: 10) {
                return signUpScreen
            }
        } while Date() < deadline
        let state = signUpLink.exists ? "the signed-out screen is still shown" : "the Sign Up link is gone"
        XCTFail("Sign up screen not shown after \(taps) taps on the Sign Up link; \(state)")
        return signUpScreen
    }

    func tapSignIn() -> Self {
        tapSignInButton(Identifiers.signInButton, "Sign in button")
    }

    func tapSignInWithoutPresentationAnchor() -> Self {
        tapSignInButton(Identifiers.signInWithoutWindowButton, "Sign in without window button")
    }

    /// Taps a sign-in button once the signed-out screen can take the tap.
    ///
    /// Back from the sign-up screen on a loaded runner, the button can be found before the pop and
    /// the keyboard's dismissal have finished, and a tap then can be dropped. So the tap waits, up
    /// to 30 s, until the sign-up screen and the keyboard are gone and the button is hittable at the
    /// same place on two polls half a second apart. The system's "Save Password?" sheet takes the
    /// tap too, so it is dismissed when it shows, and the button then settles again.
    private func tapSignInButton(_ identifier: String, _ name: String) -> Self {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 30), "\(name) not found")
        var target: TapTarget
        var lastFrame: CGRect?
        let deadline = Date().addingTimeInterval(30)
        repeat {
            if app.dismissSavePasswordPrompt() {
                lastFrame = nil
            }
            target = tapTarget(for: button)
            let frame = button.frame
            if case .hittable = target, !app.keyboards.firstMatch.exists, frame == lastFrame {
                break
            }
            lastFrame = frame
            Thread.sleep(forTimeInterval: 0.5)
        } while Date() < deadline
        if case let .blocked(reason) = target {
            XCTFail("\(name) cannot take a tap: \(reason)")
        }
        tap(button, target)
        var screen = self
        screen.tappedSignInButton = identifier
        screen.signInTappedAt = Date()
        return screen
    }

    /// How a tap can reach `button` now, or why it cannot.
    private enum TapTarget {
        /// XCUITest says the button takes a tap.
        case hittable
        /// The signed-out screen is up and the button is on it, but XCUITest calls it unhittable:
        /// a tap at its centre reaches it.
        case coordinate
        /// A tap would not reach the button, for the reason given.
        case blocked(String)
    }

    private func tapTarget(for button: XCUIElement) -> TapTarget {
        guard app.state == .runningForeground else {
            return .blocked("the app is not in the foreground (state \(app.state.rawValue))")
        }
        guard button.exists else {
            return .blocked("the button is gone")
        }
        guard !SignUpScreen(app: app).isShown else {
            return .blocked("the sign-up screen is still shown")
        }
        // Checked before `isHittable`, which can be true for a button under the sheet.
        guard !app.isSavePasswordPromptShown else {
            return .blocked("the system's Save Password? sheet is over the button")
        }
        if button.isHittable {
            return .hittable
        }
        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if alert.exists {
            return .blocked("the button is not hittable under a system alert \"\(alert.label)\"")
        }
        let frame = button.frame
        let window = app.windows.firstMatch.frame
        guard !frame.isEmpty, window.contains(CGPoint(x: frame.midX, y: frame.midY)) else {
            return .blocked("the button is not hittable and off screen")
        }
        return .coordinate
    }

    private func tap(_ button: XCUIElement, _ target: TapTarget) {
        if case .coordinate = target {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            button.tap()
        }
    }

    func dismissSignInAlert() -> Self {
        // Best effort; the real wait is in signIn(username:password:).
        tapConsentContinueIfPresent(timeout: 5)
        return self
    }

    func signIn(username: String, password: String) -> Self {
        waitForHostedUI()

        // The hosted UI names this field after the user pool's sign-in attribute, not after the
        // configuration format: "Email Email" on a pool that signs in with email (the Gen2 README
        // backend), "Username" on one that signs in with a username (the Gen1 README backend, and
        // the one pool the integration sandbox serves to both schemes). So either is accepted, the
        // configuration's usual one first, then the field by its other labels or placeholders,
        // then the page's only text field.
        let signInTextFieldNames = if useGen2Configuration {
            ["Email Email", "Username"]
        } else {
            ["Username", "Email Email"]
        }
        let otherNames = signInTextFieldNames + ["Email", "Email address", "Username or email"]
        let textFields = app.webViews.textFields
        let usernameField = waitForWebField(
            "username",
            signInTextFieldNames.map { textFields[$0] } + [
                textFields.matching(Self.labelOrPlaceholder(in: otherNames)).firstMatch,
                textFields.firstMatch
            ]
        )
        focusAndType(usernameField, username)

        let secureFields = app.webViews.secureTextFields
        let passwordField = waitForWebField(
            "password",
            [
                secureFields["Password"],
                secureFields.matching(Self.labelOrPlaceholder(in: ["Password"])).firstMatch,
                secureFields.firstMatch
            ]
        )
        focusAndType(passwordField, password)

        let submitButton = app.webViews.buttons["submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 30), "Hosted UI submit button not found")
        submitButton.tap()
        return self
    }

    private static func labelOrPlaceholder(in names: [String]) -> NSPredicate {
        NSPredicate(format: "label IN %@ OR placeholderValue IN %@", names, names)
    }

    @discardableResult
    private func tapConsentContinueIfPresent(timeout: TimeInterval) -> Bool {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let continueElement = springboard.consentContinueElement()
        if continueElement.waitForExistence(timeout: timeout) {
            continueElement.tap()
            return true
        }
        return false
    }

    /// Waits for the authentication session's web view, clearing a late consent prompt while it
    /// polls. A sign-in tap lost on a loaded runner never starts a session, so the button is tapped
    /// again, 10 s after the last tap and at most 4 times, but only while the app shows no sign-in
    /// started: the app shows it as soon as a tap reaches the button, and a second sign-in would
    /// cancel the first, and iOS 26 presents only the first session on a simulator. A "Save
    /// Password?" sheet that shows late takes the taps, so it is dismissed first. When no tap again
    /// happens, the failure says why.
    private func waitForHostedUI() {
        let webView = app.webViews.firstMatch
        let signInStarted = app.staticTexts[Identifiers.signInStartedLabel]
        var lastTap = signInTappedAt ?? Date()
        var taps = 1
        var noTapAgain = "none was due"
        let deadline = Date().addingTimeInterval(UITestTimeout.firstLoad)
        while Date() < deadline {
            tapConsentContinueIfPresent(timeout: 1)
            if webView.waitForExistence(timeout: 2) {
                return
            }
            app.dismissSavePasswordPrompt()
            if let error = signInError() {
                XCTFail("Sign in failed before the hosted UI showed: \(error)")
                return
            }
            guard let identifier = tappedSignInButton, Date().timeIntervalSince(lastTap) >= 10 else {
                continue
            }
            if signInStarted.exists {
                noTapAgain = "the sign-in started, and a second one would cancel it"
                continue
            }
            guard taps < 5 else {
                noTapAgain = "\(taps) taps is the most it makes"
                continue
            }
            let button = app.buttons[identifier]
            let target = tapTarget(for: button)
            if case let .blocked(reason) = target {
                noTapAgain = reason
                continue
            }
            tap(button, target)
            taps += 1
            lastTap = Date()
            noTapAgain = "the last tap was under 10 s before the end"
        }
        let state = signInStarted.exists ? "started the sign-in" : "shows no sign-in started"
        XCTFail("Hosted UI web view not shown after \(taps) sign-in taps; the app \(state); not tapped again: \(noTapAgain)")
    }

    /// Returns the first of `candidates` to exist, clearing a late consent prompt while it polls.
    /// Ends as soon as one exists; fails naming the page's fields when none does.
    private func waitForWebField(_ name: String, _ candidates: [XCUIElement]) -> XCUIElement {
        let deadline = Date().addingTimeInterval(60)
        repeat {
            if let element = candidates.first(where: { $0.exists }) {
                return element
            }
            tapConsentContinueIfPresent(timeout: 1)
            _ = candidates[0].waitForExistence(timeout: 2)
        } while Date() < deadline
        if let element = candidates.first(where: { $0.exists }) {
            return element
        }
        XCTFail("Hosted UI \(name) field not found; \(webPageSummary())")
        return candidates[0]
    }

    /// The web views' text fields by label and placeholder (never their values), for a failure.
    private func webPageSummary() -> String {
        let fields = app.webViews.textFields.allElementsBoundByIndex
            + app.webViews.secureTextFields.allElementsBoundByIndex
        let described = fields.map { "\($0.elementType == .secureTextField ? "secure " : "")"
            + "'\($0.label)'/'\($0.placeholderValue ?? "")'"
        }
        let error = signInError().map { "; sign-in error: \($0)" } ?? ""
        return "\(app.webViews.count) web views, fields: [\(described.joined(separator: ", "))]\(error)"
    }

    private func signInError() -> String? {
        let errorText = app.staticTexts[Identifiers.errorLabel]
        guard errorText.exists else {
            return nil
        }
        return errorText.value as? String ?? "unknown"
    }

    // iOS 26: first tap raises the keyboard, second moves focus to this field.
    private func focusAndType(_ element: XCUIElement, _ text: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 30), "Web text field not found")
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
        _ = app.keyboards.element.waitForExistence(timeout: 10)
        coordinate.tap()
        element.typeText(text)
        // A character typeText drops in a web view on a loaded runner only shows later, as a sign-in
        // that never completes. Clear and retype, at most twice, while the field shows other content.
        for _ in 0 ..< 2 where !fieldHolds(element, text) {
            let typed = (element.value as? String ?? "").count
            element.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: typed) + text)
        }
    }

    /// Whether `element` shows `text`, or true when its value cannot tell: an empty value or the
    /// placeholder, which say nothing about the content, or for a secure field anything but one
    /// bullet per character. So a retype never adds to a field whose content it cannot see.
    private func fieldHolds(_ element: XCUIElement, _ text: String) -> Bool {
        guard let value = element.value as? String, !value.isEmpty, value != element.placeholderValue else {
            return true
        }
        guard element.elementType == .secureTextField else {
            return value == text
        }
        guard value.allSatisfy({ $0 == "•" }) else {
            return true
        }
        return value.count == text.count
    }

    /// Waits for the app to show the sign-in succeeded, failing at once with the app's error or the
    /// hosted UI's own message when either shows one.
    ///
    /// A submit tap lost on a loaded runner leaves the hosted UI's form up with no answer. Once the
    /// hosted UI answers, the form goes (with a redirect the session closes) or shows a message, so
    /// submit is tapped again only while the form is still up with no message, 20 s after the last
    /// tap, and at most twice.
    func testSignInSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        let submitButton = app.webViews.buttons["submit"]
        var submits = 1
        var lastSubmit = Date()
        let deadline = Date().addingTimeInterval(90)
        while Date() < deadline {
            if successText.waitForExistence(timeout: 2) {
                return self
            }
            if let error = signInError() {
                XCTFail("SignIn operation failed: the app shows \(error)")
                return self
            }
            if let message = hostedUIMessage() {
                XCTFail("SignIn operation failed: the hosted UI shows \"\(message)\"")
                return self
            }
            if submits < 3, Date().timeIntervalSince(lastSubmit) >= 20, submitButton.exists, submitButton.isHittable {
                submitButton.tap()
                submits += 1
                lastSubmit = Date()
            }
        }
        let state = submitButton.exists
            ? "the hosted UI form is still shown; \(webPageSummary())"
            : "the hosted UI closed and the app shows no result"
        XCTFail("SignIn operation failed after \(submits) submits: \(state)")
        return self
    }

    /// The hosted UI's error message, such as "Incorrect username or password.", when it shows one.
    private func hostedUIMessage() -> String? {
        let words = ["incorrect", "error", "not exist", "invalid", "try again"]
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: words.map {
            NSPredicate(format: "label CONTAINS[c] %@", $0)
        })
        let message = app.webViews.staticTexts.matching(predicate).firstMatch
        return message.exists ? String(message.label.prefix(120)) : nil
    }
}
