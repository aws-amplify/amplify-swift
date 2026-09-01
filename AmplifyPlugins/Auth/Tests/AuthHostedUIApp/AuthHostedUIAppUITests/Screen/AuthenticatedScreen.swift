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
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let continueElement = springboard.consentContinueElement()
        if continueElement.waitForExistence(timeout: 10) {
            continueElement.tap()
        }
        return self
    }

    func testSignOutSucceeded() -> Self {
        return self
    }
}
