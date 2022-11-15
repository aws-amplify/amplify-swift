//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

struct SignInScreen: Screen {

    let app: XCUIApplication

    private enum Identifiers {
        static let signUpNav = "hostedUI_signUp_view_nav"
        static let signInButton = "hostedUI_signIn_button"
        static let signInWithoutWindowButton = "hostedUI_signIn_wo_window_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
    }

    func gotoSignUpView() -> SignUpScreen {
        let signUpButton = app.buttons[Identifiers.signUpNav]
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
        XCTAssertTrue(springboard.buttons["Continue"].waitForExistence(timeout: 5))
        springboard.buttons["Continue"].tap()
        return self
    }

    func signIn(username: String, password: String) -> Self {
        _ = app.webViews.textFields["Username"].waitForExistence(timeout: 5)
        app.webViews.textFields["Username"].tap()
        app.webViews.textFields["Username"].typeText(username)

        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText(password)

        app.webViews.buttons["submit"].tap()
        return self
    }

    func testSignInSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        XCTAssertTrue(successText.waitForExistence(timeout: 5), "SignIn operation failed")
        return self
    }
}
