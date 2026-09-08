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
        focusAndType(usernameField, username)
        focusAndType(app.webViews.secureTextFields["Password"], password)

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

    // Consent sheet can arrive late, so keep clearing it while polling.
    private func waitForWebTextField(_ element: XCUIElement) -> XCUIElement {
        let deadline = Date().addingTimeInterval(60)
        while Date() < deadline {
            tapConsentContinueIfPresent(timeout: 2)
            if element.waitForExistence(timeout: 3) {
                return element
            }
        }
        return element
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
