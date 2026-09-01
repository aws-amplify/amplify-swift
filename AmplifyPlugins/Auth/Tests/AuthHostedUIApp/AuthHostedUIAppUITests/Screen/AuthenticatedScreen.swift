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
    }

    static func signOutIfAuthenticated(app: XCUIApplication) {
        let screen = AuthenticatedScreen(app: app)
        let button = app.buttons[Identifiers.signOutButton]
        let present = button.waitForExistence(timeout: 30)
        if present {
            _ = screen.tapSignOut().dismissSignOutAlert().testSignOutSucceeded()
        }
    }

    func tapSignOut() -> Self {
        let button = app.buttons[Identifiers.signOutButton]
        button.tap()
        return self
    }

    func dismissSignOutAlert() -> Self {
        // The sign-out web session's consent sheet can appear after a delay on
        // iOS 26 CI simulators. Poll for it so we don't leave the sign-out web
        // session dangling, which would block the next sign-in from presenting.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            let continueElement = springboard.consentContinueElement()
            if continueElement.waitForExistence(timeout: 2) {
                continueElement.tap()
                break
            }
            // Already back on the signed-out screen: nothing to dismiss.
            if app.buttons[Identifiers.signInButton].exists {
                break
            }
        }
        return self
    }

    func testSignOutSucceeded() -> Self {
        // Wait until the signed-out screen is shown again, proving the sign-out
        // web session has fully closed before the next sign-in starts.
        XCTAssertTrue(
            app.buttons[Identifiers.signInButton].waitForExistence(timeout: 30),
            "Sign out did not complete"
        )
        return self
    }
}
