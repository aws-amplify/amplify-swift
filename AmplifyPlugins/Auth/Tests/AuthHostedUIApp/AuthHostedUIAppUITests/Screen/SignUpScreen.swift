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

    /// Whether the sign-up screen shows within `timeout`. Ends as soon as it does.
    func waitUntilShown(timeout: TimeInterval) -> Bool {
        app.textFields[Identifiers.usernameField].waitForExistence(timeout: timeout)
    }

    func enterFields(username: String, password: String) -> Self {
        let usernameField = app.textFields[Identifiers.usernameField]
        // Wait for the field to render before tapping; tapping immediately races the
        // screen load and fails with "No matches found".
        XCTAssertTrue(usernameField.waitForExistence(timeout: 30), "Sign up username field not found")
        usernameField.tap()
        usernameField.typeText(username)

        let passwordField = app.secureTextFields[Identifiers.passwordField]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 30), "Sign up password field not found")
        passwordField.tap()
        passwordField.typeText(password)
        return self
    }

    func tapSignUp() -> Self {
        let signUpButton = app.buttons[Identifiers.signUpButton]
        // Wait for the button before tapping; an unhittable tap silently no-ops and signup never runs.
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 30), "Sign up button not found")
        signUpButton.tap()
        return self
    }

    func testSignUpSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        if !successText.waitForExistence(timeout: 60) {
            // Surface the app's error label so a failure says *why* instead of just "failed".
            let errorText = app.staticTexts[Identifiers.errorLabel]
            let detail = errorText.exists ? SignInScreen.redacted(errorText.label) : "no error label shown"
            XCTFail("Signup operation failed: \(detail)")
        }
        return self
    }

    /// Whether the sign-up screen is on screen now.
    var isShown: Bool {
        app.textFields[Identifiers.usernameField].exists
    }

    /// Goes back to the signed-out screen and waits until the sign-up screen is gone.
    ///
    /// A Back tap lost on a loaded runner leaves the sign-up screen up, and the next sign-in tap
    /// then lands on its form. So Back is tapped again, every 10 s, while the sign-up screen is
    /// still shown and Back is hittable. The signed-out screen has no Back button, so a tap can
    /// never go past it.
    ///
    /// Once the filled-in form is gone, iOS can show its "Save Password?" sheet over the signed-out
    /// screen, a few seconds later, and the sheet takes the sign-in taps. So it is dismissed here
    /// when it shows within 5 s; the sign-in screen dismisses one that shows later.
    func returnBack() -> Self {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        let usernameField = app.textFields[Identifiers.usernameField]
        XCTAssertTrue(backButton.waitForExistence(timeout: 30), "Sign up screen's Back button not found")
        var taps = 0
        let deadline = Date().addingTimeInterval(60)
        repeat {
            if usernameField.exists, backButton.exists, backButton.isHittable {
                backButton.tap()
                taps += 1
            }
            if usernameField.waitForNonExistence(timeout: 10) {
                app.dismissSavePasswordPrompt(timeout: 5)
                return self
            }
        } while Date() < deadline
        let state = backButton.exists ? "Back is \(backButton.isHittable ? "" : "not ")hittable" : "Back is gone"
        XCTFail("Sign up screen still shown after \(taps) taps on Back; \(state)")
        return self
    }
}
