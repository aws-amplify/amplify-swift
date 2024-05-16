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
        XCTAssertTrue(springboard.buttons["Continue"].waitForExistence(timeout: 60))
        springboard.buttons["Continue"].tap()
        return self
    }


    func signIn(username: String, password: String) -> Self {
        let signInTextFieldName: String
        // Ideally we align the provisioning of Gen1 and Gen2 backends
        // to create a HostedUI endpoint that has the same username text field.
        // The Gen1 steps are updated in the README already, we re-provision the backend
        // in Gen1 according to those steps, this check can be removed and expect
        // "Email Email" to be the text field.
        if useGen2Configuration {
            signInTextFieldName = "Email Email"
        } else {
            signInTextFieldName = "Username"
        }

        _ = app.webViews.textFields[signInTextFieldName].waitForExistence(timeout: 60)
        app.webViews.textFields[signInTextFieldName].tap()
        app.webViews.textFields[signInTextFieldName].typeText(username)


        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText(password)

        app.webViews.buttons["submit"].tap()
        return self
    }

    func testSignInSucceeded() -> Self {
        let successText = app.staticTexts[Identifiers.successLabel]
        XCTAssertTrue(successText.waitForExistence(timeout: 60), "SignIn operation failed")
        return self
    }
}
