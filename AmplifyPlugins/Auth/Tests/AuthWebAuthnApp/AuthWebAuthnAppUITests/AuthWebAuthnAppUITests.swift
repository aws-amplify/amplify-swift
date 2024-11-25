//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

final class AuthWebAuthnAppUITests: XCTestCase {
    private let timeout = TimeInterval(6)
    private let app = XCUIApplication()
    private var username: String!
    private var signUpButton: XCUIElement!
    private var associateButton: XCUIElement!
    private var listButton: XCUIElement!
    private var signOutButton: XCUIElement!
    private var signInButton: XCUIElement!
    private var deleteButton: XCUIElement!
    private var deleteUserButton: XCUIElement!
    private var springboard: XCUIApplication!
    private var continueButton: XCUIElement!

    private lazy var deviceIdentifier: String = {
        let paths = Bundle.main.bundleURL.pathComponents
        guard let index = paths.firstIndex(where: { $0 == "Devices" }),
              let identifier = paths.dropFirst(index + 1).first
        else {
            fatalError("Failed to get device identifier")
        }

        return identifier
    }()

    @MainActor
    override func setUp() async throws {
        continueAfterFailure = false
        try await bootDevice()
        try await enrollBiometrics()
        if ProcessInfo.processInfo.arguments.contains("GEN2") {
            app.launchArguments.append("GEN2")
        }
        app.launch()
        loadAndValidateElements()
        signUpAndSignInUser()
    }

    @MainActor
    override func tearDown() async throws {
        deleteCurrentUser()
        app.terminate()
        username = nil
        signUpButton = nil
        associateButton = nil
        listButton = nil
        signOutButton = nil
        signInButton = nil
        deleteButton = nil
        deleteUserButton = nil
        continueButton = nil
        springboard = nil
        try await uninstallApp()
    }

    /// Because all of the WebAuthn operations are linked and some act as preconditions,
    /// we're testing them all together.
    ///
    /// This includes:
    ///  - A signed in user wants to associate a new WebAuthn credential to their account
    ///  - A signed out user wants to use their associated WebAuthn credentials to sign in
    ///  - A signed in user wants to list their associated WebAuthn credentials
    ///  - A signed in user wants to delete an associated WebAuthn credential
    ///
    @MainActor
    func testWebAuthnAPIs() async throws {
        // 1. Associate new WebAuthn Credential
        let associateAttempt = await attempt {
            associateButton.tap()
            return !waitForResult("Associate WebAuthn Credential failed:", timeout: 1)
        }

        guard associateAttempt else {
            XCTFail("Failed to trigger the Associate WebAuthn Credential workflow")
            return
        }

        // Wait for the "Continue" button to appear in the FaceID popover and tap it
        guard continueButton.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find 'Continue' button")
            return
        }
        continueButton.tap()

        // Trigger a matching face
        try await matchBiometrics()
        guard waitForResult("WebAuthn credential was associated") else {
            XCTFail("Failed to associate credential")
            return
        }

        // 2. List existing credentials
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 1") else {
            XCTFail("Failed to list credentials")
            return
        }

        // 3. Sign Out
        signOutButton.tap()
        guard waitForResult("User is signed out"), signInButton.exists else {
            XCTFail("Failed to sign out user")
            return
        }

        // 4. Sign in with WebAuthn
        let signInAttempt = await attempt {
            signInButton.tap()
            return !waitForResult("Sign In failed:", timeout: 1)
        }

        guard signInAttempt else {
            XCTFail("Failed to trigger the Assert WebAuthn Credential workflow")
            return
        }

        // Wait for the "Continue" button to appear in the FaceID popover
        guard continueButton.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find 'Continue' button")
            return
        }

        // If presented with additional credentials, choose the one for this user by tapping on it
        let webAuthnCredentialButton = springboard.staticTexts[username]
        if webAuthnCredentialButton.waitForExistence(timeout: 1) {
            webAuthnCredentialButton.tap()
        }

        // Tap the "Continue" button
        continueButton.tap()

        // Trigger a matching face
        try await matchBiometrics()

        guard waitForResult("User is signed in") else {
            XCTFail("Failed to Sign In with WebAuthn")
            return
        }

        // 5. Delete credential
        deleteButton.tap()
        guard waitForResult("WebAuthn credential was deleted") else {
            XCTFail("Failed to delete credential")
            return
        }

        // 6. Verify deletion
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 0") else {
            XCTFail("Failed to list credentials")
            return
        }
    }

    private func bootDevice() async throws {
        let request = LocalServer.boot(deviceIdentifier).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to boot the device")
    }

    private func enrollBiometrics() async throws {
        let request = LocalServer.enroll(deviceIdentifier).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to enroll biometrics in the device")
    }

    private func matchBiometrics() async throws {
        let request = LocalServer.match(deviceIdentifier).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to match biometrics in the device")
    }

    private func uninstallApp() async throws {
        let request = LocalServer.uninstall(deviceIdentifier).urlRequest
        let (_, response) = try await URLSession.shared.data(for: request)
        XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to uninstall the App")
    }

    @MainActor
    private func loadAndValidateElements() {
        let usernameElement = app.staticTexts["Username"]
        guard usernameElement.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find the Username label")
            return
        }

        username = usernameElement.label

        // Once the Username label exists, all these button are expected to visible as well,
        // so we don't wait for them and instead just check for their existence
        signUpButton = app.buttons["SignUp"]
        guard signUpButton.exists else {
            XCTFail("Failed to find the 'Sign Up and Sign In' button")
            return
        }

        associateButton = app.buttons["AssociateWebAuthn"]
        guard associateButton.exists else {
            XCTFail("Failed to find the 'Associate WebAuthn Credential' button")
            return
        }

        listButton = app.buttons["ListWebAuthn"]
        guard listButton.exists else {
            XCTFail("Failed to find the 'List WebAuthn Credentials' button")
            return
        }

        deleteButton = app.buttons["DeleteWebAuthn"]
        guard deleteButton.exists else {
            XCTFail("Failed to find the 'Delete WebAuthn Credential' button")
            return
        }

        deleteUserButton = app.buttons["DeleteUser"]
        guard deleteUserButton.exists else {
            XCTFail("Failed to find the 'Delete User' button")
            return
        }

        // The Sign In and Sign Out buttons only become visible when Sign Up and Sign In are completed respectively,
        // so we don't check their existance.
        signInButton = app.buttons["SignIn"]
        signOutButton = app.buttons["SignOut"]

        springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // The Continue button only appears when a FaceID operation is triggered,
        // so we're also not checking for its existance
        continueButton = springboard.otherElements["ASAuthorizationControllerContinueButton"]
    }

    @MainActor
    private func signUpAndSignInUser() {
        signUpButton.tap()
        guard waitForResult("User is signed in"), signOutButton.exists else {
            XCTFail("Failed to Sign Up and Sign In")
            return
        }
    }

    @MainActor
    private func deleteCurrentUser() {
        guard let deleteUserButton else {
            XCTFail("Failed to find the 'Delete User' button")
            return
        }
        deleteUserButton.tap()
        guard waitForResult("User was deleted"), signUpButton.exists else {
            XCTFail("Failed to delete the user")
            return
        }
    }

    @MainActor
    private func waitForResult(_ containing: String, timeout: TimeInterval? = nil) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", containing)
        let element = app.staticTexts.matching(identifier: "LastResult")
            .matching(predicate).firstMatch
        return element.waitForExistence(timeout: timeout ?? self.timeout)
    }

    @MainActor
    private func attempt(times: Int = 3, _ action: () async -> Bool) async -> Bool {
        let result = await action()
        if !result, times > 0 {
            sleep(5)
            return await attempt(times: times - 1, action)
        }
        return result
    }
}
