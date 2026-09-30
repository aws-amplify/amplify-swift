//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

struct SignInScreen: Screen {

    let app: XCUIApplication

    var useGen2Configuration: Bool {
        ProcessInfo.processInfo.arguments.contains("GEN2")
    }

    private enum Identifiers {
        static let signUpNav = "hostedUI_signUp_view_nav"
        static let signInButton = "hostedUI_signIn_button"
        static let signInWithoutWindowButton = "hostedUI_signIn_wo_window_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
    }

    func gotoSignUpView() -> SignUpScreen {
        let signUpButton = app.buttons[Identifiers.signUpNav]
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 30))
        signUpButton.tap()
        return SignUpScreen(app: app)
    }

    func tapSignIn() -> Self {
        let button = app.buttons[Identifiers.signInButton]
        button.tap()
        return self
    }

    func tapSignInWithoutPresentationAnchor() -> Self {
        let button = app.buttons[Identifiers.signInWithoutWindowButton]
        button.tap()
        return self
    }

    func dismissSignInAlert() -> Self {
        // Best effort; the real wait is in signIn(username:password:).
        tapConsentContinueIfPresent(timeout: 5)
        return self
    }


    func signIn(username: String, password: String) -> Self {
        // The hosted UI names this field after the user pool's sign-in attribute, not after the
        // configuration format: "Email Email" on a pool that signs in with email (the Gen2 README
        // backend), "Username" on one that signs in with a username (the Gen1 README backend, and
        // the one pool the integration sandbox serves to both schemes). So either is accepted, the
        // configuration's usual one first.
        let signInTextFieldNames = if useGen2Configuration {
            ["Email Email", "Username"]
        } else {
            ["Username", "Email Email"]
        }

        let usernameField = waitForWebTextField(signInTextFieldNames.map { app.webViews.textFields[$0] })
        focusAndType(usernameField, username)
        // Route the password field through the same consent-clearing poll as the username
        // field; a late consent sheet can otherwise hide it past `focusAndType`'s plain wait.
        let passwordField = waitForWebTextField([app.webViews.secureTextFields["Password"]])
        focusAndType(passwordField, password)

        app.webViews.buttons["submit"].tap()
        return self
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

    // Consent sheet can arrive late, so keep clearing it while polling. Returns the first of
    // `elements` found (or the first, to fail on, if none is found in time).
    private func waitForWebTextField(_ elements: [XCUIElement]) -> XCUIElement {
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            tapConsentContinueIfPresent(timeout: 2)
            if elements[0].waitForExistence(timeout: 3) {
                return elements[0]
            }
            if let element = elements.dropFirst().first(where: { $0.exists }) {
                return element
            }
        }
        return elements[0]
    }

    // iOS 26: first tap raises the keyboard, second moves focus to this field.
    private func focusAndType(_ element: XCUIElement, _ text: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 30), "Web text field not found")
        let coordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coordinate.tap()
        _ = app.keyboards.element.waitForExistence(timeout: 10)
        coordinate.tap()
        element.typeText(text)
    }

    func testSignInSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        XCTAssertTrue(successText.waitForExistence(timeout: 60), "SignIn operation failed")
        return self
    }
}
