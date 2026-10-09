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

enum UITestTimeout {
    /// The app's first screen after a launch. On a loaded runner the launch on a cold simulator and
    /// the app's first auth state check took up to a minute.
    static let firstLoad: TimeInterval = 90
}

extension XCUIApplication {
    // "Continue" is no longer a button on iOS 26.
    func consentContinueElement() -> XCUIElement {
        descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Continue"))
            .firstMatch
    }

    /// Returns the first of `elements` to exist, or nil when none does within `timeout`. Ends as
    /// soon as one exists.
    func waitForFirst(of elements: [XCUIElement], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let element = elements.first(where: { $0.exists }) {
                return element
            }
            _ = elements[0].waitForExistence(timeout: 1)
        } while Date() < deadline
        return elements.first(where: { $0.exists })
    }
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
