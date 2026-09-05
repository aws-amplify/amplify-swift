//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

protocol Screen {
    var app: XCUIApplication { get }
}

extension XCUIApplication {
    /// Matches the SpringBoard consent "Continue" control by label across any
    /// element type, since it is no longer a button on iOS 26.
    func consentContinueElement() -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Continue"))
            .firstMatch
    }
}

class UITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        if ProcessInfo.processInfo.arguments.contains("GEN2") {
            app.launchArguments.append("GEN2")
        }
        app.launch()

        AuthenticatedScreen.signOutIfAuthenticated(app: app)
    }

    override func tearDown() {
        app.terminate()
    }
}
