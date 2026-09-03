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

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class UITestCase: XCTestCase, @unchecked Sendable {
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
