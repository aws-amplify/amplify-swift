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
        // With an ephemeral web session iOS may not show the consent sheet at
        // all; when it does it can appear after a noticeable delay. Tapping it
        // is handled together with the field wait in `signIn(username:password:)`,
        // so this is only a best-effort early dismissal.
        tapConsentContinueIfPresent(timeout: 5)
        return self
    }


    func signIn(username: String, password: String) -> Self {
        let signInTextFieldName
        // Ideally we align the provisioning of Gen1 and Gen2 backends
        // to create a HostedUI endpoint that has the same username text field.
        // The Gen1 steps are updated in the README already, we re-provision the backend
        // in Gen1 according to those steps, this check can be removed and expect
        // "Email Email" to be the text field.
        = if useGen2Configuration {
            "Email Email"
        } else {
            "Username"
        }

        let usernameField = waitForWebTextField(app.webViews.textFields[signInTextFieldName])
        focusAndType(usernameField, username, fieldDescription: "Username")
        focusAndType(
            app.webViews.secureTextFields["Password"],
            password,
            fieldDescription: "Password"
        )

        app.webViews.buttons["submit"].tap()
        return self
    }

    /// Taps the SpringBoard consent "Continue" control if it is present.
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

    /// Waits for the Hosted UI web field to appear, dismissing the consent sheet
    /// if it shows up late. The Hosted UI page can be slow to load on iOS 26 CI
    /// simulators, so we poll while also clearing a late consent sheet.
    private func waitForWebTextField(_ element: XCUIElement) -> XCUIElement {
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            tapConsentContinueIfPresent(timeout: 2)
            if element.waitForExistence(timeout: 3) {
                return element
            }
            failIfSignInReportedError()
        }
        return element
    }

    /// The app reports Amplify failures in a label instead of throwing, so a
    /// rejected `signInWithWebUI` (which never presents the Hosted UI) is
    /// indistinguishable from a slow page load. Surface the reported error so the
    /// real cause appears in the test output instead of a generic field timeout.
    private func failIfSignInReportedError() {
        let errorText = app.staticTexts[Identifiers.errorLabel]
        guard errorText.exists else { return }
        XCTFail("SignIn failed before the Hosted UI was shown: \(errorText.label)")
    }

    /// iOS 26: a WebView field only accepts typed input once it actually holds
    /// keyboard focus. The software keyboard can already be up from a previously
    /// focused field, so waiting on `app.keyboards` is not enough to know that
    /// *this* field is focused. Tap the field's center coordinate (which focuses
    /// WKWebView inputs more reliably than `tap()`) once to raise the keyboard,
    /// then again to guarantee focus has moved to this field before typing.
    private func focusAndType(
        _ element: XCUIElement,
        _ text: String,
        fieldDescription: String
    ) {
        if !element.waitForExistence(timeout: 30) {
            failIfSignInReportedError()
            XCTFail("\(fieldDescription) web text field not found")
            return
        }
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
