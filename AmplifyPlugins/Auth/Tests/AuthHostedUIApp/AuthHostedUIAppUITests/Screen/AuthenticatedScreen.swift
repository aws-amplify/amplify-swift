//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

struct AuthenticatedScreen: Screen {
    let app: XCUIApplication


    private enum Identifiers {
        static let signOutButton = "hostedUI_signOut_button"
        static let signInButton = "hostedUI_signIn_button"
        static let signUpNav = "hostedUI_signUp_view_nav"
    }

    static func signOutIfAuthenticated(app: XCUIApplication) {
        // The app shows nothing until it knows whether a user is signed in, then the signed-in or
        // the signed-out screen. Wait for whichever comes first rather than for the sign-out button
        // alone, which spent a fixed 30 s on every signed-out launch and left a slow first load to
        // the next step's shorter wait.
        let signOutButton = app.buttons[Identifiers.signOutButton]
        let shown = app.waitForFirst(
            of: [signOutButton, app.buttons[Identifiers.signUpNav]],
            timeout: UITestTimeout.firstLoad
        )
        XCTAssertNotNil(shown, "The app showed neither the signed-in nor the signed-out screen")
        if shown === signOutButton {
            _ = AuthenticatedScreen(app: app).tapSignOut().dismissSignOutAlert().testSignOutSucceeded()
        }
    }

    func tapSignOut() -> Self {
        let button = app.buttons[Identifiers.signOutButton]
        button.tap()
        return self
    }

    func dismissSignOutAlert() -> Self {
        // Consent sheet can arrive late on iOS 26 simulators.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            let continueElement = springboard.consentContinueElement()
            if continueElement.waitForExistence(timeout: 2) {
                continueElement.tap()
                break
            }
            if app.buttons[Identifiers.signInButton].exists {
                break
            }
        }
        return self
    }

    func testSignOutSucceeded() -> Self {
        XCTAssertTrue(
            app.buttons[Identifiers.signInButton].waitForExistence(timeout: 30),
            "Sign out did not complete"
        )
        return self
    }
}
