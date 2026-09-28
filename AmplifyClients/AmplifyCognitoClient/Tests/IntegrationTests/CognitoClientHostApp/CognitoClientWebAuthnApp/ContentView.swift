//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The plugin's `AuthWebAuthnApp` screen, button for button: the same accessibility identifiers and
/// the same result lines, so the client's UI tests follow the plugin's `testWebAuthnAPIs` step for step.
struct ContentView: View {
    let driver: Result<WebAuthnHarnessDriver, HarnessAppError>

    @State private var lastResult: String = ""
    @State private var credentialId: String = ""
    @State private var isSignedUp: Bool = false
    @State private var isSignedIn: Bool = false
    /// Set while an action runs. A tap during it is ignored, so a UI test that retries a tap because
    /// the passkey sheet was slow to appear cannot start a second ceremony behind the first.
    @State private var isBusy: Bool = false
    @State private var busyAction: String = ""
    @State private var current: Task<Void, Never>?

    // `ccit-` so infra/parity.py cleanup (P-12) removes a user a crashed run leaves behind. Lower case,
    // because the passkey sheet lists the user name as Cognito stores it.
    private let username = "ccit-webauthn-\(UUID().uuidString.prefix(8))".lowercased()
    private let password = "Ccit-\(UUID().uuidString)-1!"
    private var email: String { "\(username)@example.com" }

    var body: some View {
        ScrollView {
            VStack {
                Text(username)
                    .accessibilityIdentifier("Username")
                Text(driverName)
                    .font(.caption)
                    .accessibilityIdentifier("Driver")
                Divider()
                if isSignedIn {
                    Button("Sign Out") {
                        run("Sign Out") { driver in
                            try await driver.signOut()
                            isSignedIn = false
                            return "User is signed out"
                        }
                    }
                    .accessibilityIdentifier("SignOut")
                } else if isSignedUp {
                    Button("Sign In") {
                        run("Sign In") { driver in
                            try await driver.signInWithWebAuthn(username: username, presentationAnchor: WebAuthnHarness.keyWindow())
                            isSignedIn = true
                            return "User is signed in"
                        }
                    }
                    .accessibilityIdentifier("SignIn")
                } else {
                    Button("Sign Up and Sign In") {
                        run("Sign Up") { driver in
                            try await driver.signUpAndSignIn(username: username, password: password, email: email) {
                                isSignedUp = true
                            }
                            isSignedIn = true
                            return "User is signed in"
                        }
                    }
                    .accessibilityIdentifier("SignUp")
                }

                Button("Associate WebAuthn Credential") {
                    run("Associate WebAuthn Credential") { driver in
                        try await driver.associateWebAuthnCredential(presentationAnchor: WebAuthnHarness.keyWindow())
                        return "WebAuthn credential was associated"
                    }
                }
                .accessibilityIdentifier("AssociateWebAuthn")

                Button("List WebAuthn Credentials") {
                    run("List WebAuthn Credentials") { driver in
                        let credentials = try await driver.listWebAuthnCredentials()
                        credentialId = credentials.first ?? ""
                        return "WebAuthn Credentials: \(credentials.count)"
                    }
                }
                .accessibilityIdentifier("ListWebAuthn")

                Button("Delete WebAuthn Credential") {
                    run("Delete WebAuthn Credential") { driver in
                        try await driver.deleteWebAuthnCredential(credentialId: credentialId)
                        return "WebAuthn credential was deleted"
                    }
                }
                .accessibilityIdentifier("DeleteWebAuthn")

                Button("Delete User") {
                    run("Delete User") { driver in
                        try await driver.deleteUser(username: username, password: password)
                        isSignedIn = false
                        isSignedUp = false
                        return "User was deleted"
                    }
                }
                .accessibilityIdentifier("DeleteUser")

                // Ends a ceremony whose sheet never appeared (the UI test's retry) or that is stuck, so
                // the next action can run.
                Button("Cancel Passkey Ceremony") {
                    if case .success(let driver) = driver {
                        driver.cancelCeremony()
                    }
                    current?.cancel()
                }
                .font(.caption)
                .accessibilityIdentifier("CancelCeremony")

                // Waits for the simulator to verify the relying party's association (the UI tests run it after
                // every launch, before the flow), so the first ceremony does not meet 1004.
                Button("Warm Up") {
                    run("Warm Up") { _ in
                        let probes = try await AssociationWarmUp(anchor: WebAuthnHarness.keyWindow()).run()
                        return "Warm-up finished after \(probes) probes"
                    }
                }
                .font(.caption)
                .accessibilityIdentifier("WarmUp")

                if isSignedUp {
                    // The user exists (the raw SignUp succeeded), so the UI test deletes it whatever happens next.
                    Text("Signed up")
                        .font(.caption)
                        .accessibilityIdentifier("SignedUp")
                }

                if isBusy {
                    Text("Busy: \(busyAction)")
                        .font(.caption)
                        .accessibilityIdentifier("Busy")
                }

                Divider()

                Text(lastResult)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .accessibilityIdentifier("LastResult")

                Spacer()
            }
            .padding()
        }
    }

    private var driverName: String {
        switch driver {
        case .success(let driver): return "Driver: \(driver.name)"
        case .failure: return "Driver: unavailable"
        }
    }

    /// Runs one button's action and shows its outcome, `"<action> failed: <error>"` on failure, as the
    /// plugin's screen does. While it runs, "Busy" is shown and other taps are ignored, so a second
    /// ceremony never starts behind the first: a caller that wants to retry cancels first.
    private func run(_ action: String, _ body: @escaping @MainActor (WebAuthnHarnessDriver) async throws -> String) {
        guard !isBusy else {
            return
        }
        isBusy = true
        busyAction = action
        lastResult = ""
        current = Task { @MainActor in
            defer {
                isBusy = false
                current = nil
            }
            switch driver {
            case .failure(let error):
                lastResult = "\(action) failed: \(error)"
            case .success(let driver):
                do {
                    lastResult = try await body(driver)
                } catch {
                    lastResult = "\(action) failed: \(error)"
                }
            }
        }
    }
}
