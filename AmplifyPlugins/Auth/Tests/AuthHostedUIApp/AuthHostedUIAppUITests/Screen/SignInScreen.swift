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
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let continueElement = springboard.consentContinueElement()
        if continueElement.waitForExistence(timeout: 10) {
            continueElement.tap()
        }
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

        focusAndType(app.webViews.textFields[signInTextFieldName], username)
        focusAndType(app.webViews.secureTextFields["Password"], password)

        app.webViews.buttons["submit"].tap()
        return self
    }

    /// iOS 26: tap until the software keyboard is up before typing to avoid dropped input.
    private func focusAndType(_ element: XCUIElement, _ text: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 60), "Web text field not found")
        element.tap()
        var attempts = 0
        while !app.keyboards.element.waitForExistence(timeout: 5) && attempts < 3 {
            element.tap()
            attempts += 1
        }
        element.typeText(text)
    }

    func testSignInSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        XCTAssertTrue(successText.waitForExistence(timeout: 60), "SignIn operation failed")
        return self
    }
}
