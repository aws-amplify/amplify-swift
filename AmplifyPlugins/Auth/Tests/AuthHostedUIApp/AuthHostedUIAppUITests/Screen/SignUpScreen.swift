//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

struct SignUpScreen: Screen {
    let app: XCUIApplication

    private enum Identifiers {
        static let usernameField = "hostedUI_signup_username_field"
        static let passwordField = "hostedUI_signup_password_field"
        static let signUpButton = "hostedUI_signup_button"

        static let successLabel = "hostedUI_success_text"
        static let errorLabel = "hostedUI_error_text"
    }

    func enterFields(username: String, password: String) -> Self {
        let usernameField = app.textFields[Identifiers.usernameField]
        usernameField.tap()
        usernameField.typeText(username)

        let passwordField = app.secureTextFields[Identifiers.passwordField]
        passwordField.tap()
        passwordField.typeText(password)
        return self
    }

    func tapSignUp() -> Self {
        let signUpButton = app.buttons[Identifiers.signUpButton]
        signUpButton.tap()
        return self
    }

    func testSignUpSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        XCTAssertTrue(successText.waitForExistence(timeout: 5), "Signup operation failed")
        return self
    }

    func returnBack() -> Self {
        app.navigationBars.buttons.element(boundBy: 0).tap()
        return self
    }
}
