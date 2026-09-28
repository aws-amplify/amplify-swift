//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
final class AuthWebAuthnAppUITests: XCTestCase, @unchecked Sendable {
    private let timeout = TimeInterval(30)
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
        // A passkey sheet left open keeps its ceremony, and so the app, busy: close it first.
        if springboard != nil {
            for host in sheetHosts {
                let close = host.buttons.matching(
                    NSPredicate(format: "label IN %@", ["close", "Close", "Cancel"])
                ).firstMatch
                // Only a hittable one: tapping anything else fails the test here and would skip the
                // user deletion and uninstall below.
                if close.exists, close.isHittable {
                    close.tap()
                }
            }
        }
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
        guard let associateContinueButton = await passkeySheetButton(after: associateButton) else {
            XCTFail("Failed to find the 'Continue' button to Associate new WebAuthn credential: \(lastResult)")
            return
        }
        associateContinueButton.tap()

        // Trigger a matching face
        try await matchBiometrics()
        guard waitForResult("WebAuthn credential was associated") else {
            XCTFail("Failed to associate credential: \(lastResult)")
            return
        }

        // 2. List existing credentials
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 1") else {
            XCTFail("Failed to list credentials: \(lastResult)")
            return
        }

        // 3. Sign Out
        signOutButton.tap()
        guard waitForResult("User is signed out"), signInButton.exists else {
            XCTFail("Failed to sign out user: \(lastResult)")
            return
        }

        // 4. Sign in with WebAuthn
        guard let signInContinueButton = await passkeySheetButton(after: signInButton) else {
            XCTFail("Failed to find the 'Continue' button to Sign In with WebAuthn: \(lastResult)")
            return
        }

        // If presented with additional credentials, choose the one for this user by tapping on it
        for host in sheetHosts {
            let webAuthnCredentialButton = host.staticTexts[username]
            if webAuthnCredentialButton.exists {
                webAuthnCredentialButton.tap()
                break
            }
        }

        // Tap the "Continue" button
        signInContinueButton.tap()

        // Trigger a matching face
        try await matchBiometrics()

        guard waitForResult("User is signed in") else {
            XCTFail("Failed to Sign In with WebAuthn: \(lastResult)")
            return
        }

        // 5. Delete credential
        deleteButton.tap()
        guard waitForResult("WebAuthn credential was deleted") else {
            XCTFail("Failed to delete credential: \(lastResult)")
            return
        }

        // 6. Verify deletion
        listButton.tap()
        guard waitForResult("WebAuthn Credentials: 0") else {
            XCTFail("Failed to list credentials: \(lastResult)")
            return
        }
    }

    private func bootDevice() async throws {
        try await sendLocalServerRequest(LocalServer.boot(deviceIdentifier), description: "boot the device")
    }

    private func enrollBiometrics() async throws {
        try await sendLocalServerRequest(LocalServer.enroll(deviceIdentifier), description: "enroll biometrics in the device")
    }

    private func matchBiometrics() async throws {
        try await sendLocalServerRequest(LocalServer.match(deviceIdentifier), description: "match biometrics in the device")
    }

    private func uninstallApp() async throws {
        try await sendLocalServerRequest(LocalServer.uninstall(deviceIdentifier), description: "uninstall the App")
    }

    // The local biometrics-control server can be briefly slow/unresponsive; retry instead of
    // failing the whole test on a single -1001 timeout.
    private func sendLocalServerRequest(_ server: LocalServer, description: String, attempts: Int = 3) async throws {
        var request = server.urlRequest
        request.timeoutInterval = 20
        var lastError: Error?
        for attempt in 1 ... attempts {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                XCTAssertTrue((response as! HTTPURLResponse).statusCode < 300, "Failed to \(description)")
                return
            } catch {
                lastError = error
                if attempt < attempts { try? await Task.sleep(nanoseconds: 2_000_000_000) }
            }
        }
        throw try XCTUnwrap(lastError)
    }

    @MainActor
    private func loadAndValidateElements() {
        let usernameElement = app.staticTexts["Username"]
        guard usernameElement.waitForExistence(timeout: timeout) else {
            XCTFail("Failed to find the Username label")
            return
        }

        username = usernameElement.label.lowercased()

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
    }

    @MainActor
    private func signUpAndSignInUser() {
        signUpButton.tap()
        guard waitForResult("User is signed in"), signOutButton.exists else {
            XCTFail("Failed to Sign Up and Sign In: \(lastResult)")
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
            XCTFail("Failed to delete the user: \(lastResult)")
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

    /// The processes that host the system passkey sheet: SpringBoard before iOS 26,
    /// AuthenticationServicesUI on iOS 26.
    @MainActor
    private var sheetHosts: [XCUIApplication] {
        [springboard, XCUIApplication(bundleIdentifier: "com.apple.AuthenticationServicesUI")]
    }

    /// Taps `button` and returns the passkey sheet's confirming button. On a freshly booted simulator
    /// the first ceremony can fail before any sheet appears (the relying party's association is still
    /// being fetched), so a failed ceremony is retried, up to 3 times. It taps again only once the
    /// previous ceremony has reported its failure: tapping while a sheet is still coming up starts a
    /// second ceremony, and the first one then never completes.
    @MainActor
    private func passkeySheetButton(after button: XCUIElement, attempts: Int = 3) async -> XCUIElement? {
        for attempt in 1 ... attempts {
            // The previous result (a failure, on a retry) stays up until the app starts the new action:
            // wait for it to change, so it is not read as this attempt's failure.
            let previousResult = lastResult
            button.tap()
            // Nothing to wait for when there was no result: the new one cannot be confused with it.
            let deadline = Date().addingTimeInterval(previousResult.isEmpty ? 0 : 10)
            while lastResult == previousResult, Date() < deadline {
                pause()
            }
            if let sheetButton = passkeySheetButton() {
                return sheetButton
            }
            guard attempt < attempts, lastResult.contains("failed") else {
                return nil
            }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
        }
        return nil
    }

    /// The passkey sheet's confirming button, by the identifier this test used to query SpringBoard's
    /// `otherElements` for, in any element type, else by its label ("Add Passkey" when saving one on
    /// iOS 26). Waits up to 90 s, and returns nil early if the ceremony has already failed.
    @MainActor
    private func passkeySheetButton() -> XCUIElement? {
        let deadline = Date().addingTimeInterval(90)
        let byLabel = NSPredicate(format: "label IN %@", ["Continue", "Add Passkey", "Sign In", "Save Passkey"])
        repeat {
            if lastResult.contains("failed") {
                return nil
            }
            for host in sheetHosts {
                // Hittable, not merely present: a tap while the sheet is still sliding in is lost.
                let byIdentifier = host.descendants(matching: .any)["ASAuthorizationControllerContinueButton"]
                if byIdentifier.exists, byIdentifier.isHittable {
                    return byIdentifier
                }
                let labelled = host.buttons.matching(byLabel).firstMatch
                if labelled.exists, labelled.isHittable {
                    return labelled
                }
            }
            pause()
        } while Date() < deadline
        return nil
    }

    /// Half a second, letting the run loop turn (a blocking sleep gets the UI test runner killed). The
    /// sheet's button can exist without being hittable yet, so the loops above must not spin on it.
    @MainActor
    private func pause() {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "pause")], timeout: 0.5)
    }

    private var lastResult: String {
        let result = app.staticTexts["LastResult"]
        // SwiftUI drops an empty Text from the hierarchy: no element means the action is still running.
        return result.exists ? result.label : ""
    }
}
