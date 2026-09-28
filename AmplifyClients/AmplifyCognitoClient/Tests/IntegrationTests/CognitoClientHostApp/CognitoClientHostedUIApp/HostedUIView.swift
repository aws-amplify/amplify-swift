//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import SwiftUI

/// The plugin's `AuthHostedUIApp` screens (`SignedOutView`, `SignedInView`) as one screen over the client:
/// sign in with the view's window (HU-1), sign in with a window the app looks up itself (HU-2), and sign
/// out. Every action reports on the `LastResult` line, `"<action> failed: <error>"` on
/// failure, as the WebAuthn app does.
struct HostedUIView: View {
    let client: Result<AmplifyCognitoClient, HarnessAppError>

    @State private var windowHolder = WindowHolder()
    /// Nil until the saved session has been read at launch.
    @State private var isSignedIn: Bool?
    @State private var currentUsername = ""
    @State private var lastResult = ""
    /// Set while an action runs. A tap during it is ignored, so a retried tap cannot start a second
    /// browser behind the first: a caller that wants to retry cancels first.
    @State private var isBusy = false
    @State private var busyAction = ""
    @State private var current: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            Text(sessionStateText)
                .accessibilityIdentifier("SessionState")
            if isSignedIn == true {
                Text(currentUsername)
                    .font(.caption)
                    .accessibilityIdentifier("CurrentUser")
                Button("Sign Out") {
                    run("Sign Out") { client in
                        try await signOut(client)
                    }
                }
                .accessibilityIdentifier("SignOut")
            } else if isSignedIn == false {
                Button("Sign In") {
                    run("Sign In") { client in
                        guard let window = windowHolder.window else {
                            throw HarnessAppError("The view is in no window")
                        }
                        return try await signIn(client, presentationAnchor: window)
                    }
                }
                .accessibilityIdentifier("SignIn")

                Button("Sign In, App-Resolved Window") {
                    run("Sign In") { client in
                        guard let window = HostedUIHarness.foregroundKeyWindow() else {
                            throw HarnessAppError("The app has no foreground window")
                        }
                        return try await signIn(client, presentationAnchor: window)
                    }
                }
                .accessibilityIdentifier("SignInResolvingWindow")
            }

            // Ends a sign-in whose browser is stuck or never appeared, so the next action can run.
            Button("Cancel Web UI Sign-In") {
                if case .success(let client) = client {
                    Task { await client.cancelWebUISignIn() }
                }
                current?.cancel()
            }
            .font(.caption)
            .accessibilityIdentifier("CancelWebUI")

            if isBusy {
                Text("Busy: \(busyAction)")
                    .font(.caption)
                    .accessibilityIdentifier("Busy")
            }

            Divider()

            // Absent while an action runs (its line is cleared when it starts), so a test waiting for the line
            // never reads an empty one.
            if !lastResult.isEmpty {
                Text(lastResult)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .accessibilityIdentifier("LastResult")
            }

            Spacer()
        }
        .padding()
        .background(WindowReader(holder: windowHolder))
        .task {
            await loadSessionState()
        }
    }

    private var sessionStateText: String {
        switch isSignedIn {
        case .none: return "Loading"
        case .some(true): return "Signed in"
        case .some(false): return "Signed out"
        }
    }

    /// The saved session at launch: signed in if `getCurrentUser` names a user.
    private func loadSessionState() async {
        switch client {
        case .failure(let error):
            lastResult = "Configure failed: \(error)"
            isSignedIn = false
        case .success(let client):
            do {
                currentUsername = try await client.getCurrentUser().username
                isSignedIn = true
            } catch AuthClientError.notSignedIn {
                isSignedIn = false
            } catch {
                lastResult = "Load failed: \(error)"
                isSignedIn = false
            }
        }
    }

    /// Private (ephemeral), as the plugin's app asks with `.preferPrivateSession()`, so no cookie from an
    /// earlier run can skip the login form. It is also the client's default.
    private func signIn(_ client: AmplifyCognitoClient, presentationAnchor: UIWindow) async throws -> String {
        let result = try await client.signInWithWebUI(
            presentationAnchor: presentationAnchor,
            options: WebUIOptions(prefersEphemeralSession: true)
        )
        guard case .done = result.nextStep else {
            return "Sign In returned an unexpected next step"
        }
        currentUsername = try await client.getCurrentUser().username
        isSignedIn = true
        return "User is signed in"
    }

    /// `signOut(presentationAnchor:)` with the view's window. After a private sign-in it shows nothing
    /// (no cookie to clear) and revokes the tokens. The row is purged, so a run leaves nothing behind.
    private func signOut(_ client: AmplifyCognitoClient) async throws -> String {
        guard let window = windowHolder.window ?? HostedUIHarness.foregroundKeyWindow() else {
            throw HarnessAppError("The view is in no window")
        }
        let result = try await client.signOut(
            presentationAnchor: window,
            options: AuthClientSignOutOptions(purgeStoredSession: true)
        )
        guard result == .complete else {
            return "Sign Out did not complete: \(result)"
        }
        do {
            _ = try await client.getCurrentUser()
            return "Sign Out left a user signed in"
        } catch AuthClientError.notSignedIn {
            isSignedIn = false
            currentUsername = ""
            return "User is signed out"
        }
    }

    private func run(_ action: String, _ body: @escaping @MainActor (AmplifyCognitoClient) async throws -> String) {
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
            switch client {
            case .failure(let error):
                lastResult = "\(action) failed: \(error)"
            case .success(let client):
                do {
                    lastResult = try await body(client)
                } catch {
                    lastResult = "\(action) failed: \(error)"
                }
            }
        }
    }
}
