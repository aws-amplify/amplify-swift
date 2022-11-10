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

class UITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        AuthenticatedScreen.signOutIfAuthenticated(app: app)
    }

    override func tearDown() {
        app.terminate()
    }
}
