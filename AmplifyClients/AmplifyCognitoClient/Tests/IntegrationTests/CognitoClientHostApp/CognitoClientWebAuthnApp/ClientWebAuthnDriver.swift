//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// WA-1: the client's WebAuthn API. This file compiles with COGNITO_CLIENT_WEBAUTHN_API, which
// CognitoClientWebAuthn.xcconfig turns on.
// WA-0 runs the same flow over the raw Cognito API.
#if COGNITO_CLIENT_WEBAUTHN_API
@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation

@MainActor
final class ClientWebAuthnDriver: WebAuthnHarnessDriver {
    let name = "AmplifyCognitoClient"

    private let client: AmplifyCognitoClient
    private let signUp: CognitoIdentityProviderClient
    private let clientId: String
    private let configuration: AuthClientConfiguration

    init(configuration: AuthClientConfiguration) throws {
        guard let userPool = configuration.userPool else {
            throw HarnessAppError("The WebAuthn pool outputs have no user pool")
        }
        // A fresh session per launch, so a crashed run's record is never restored into this one.
        self.client = try AmplifyCognitoClient(
            configuration: configuration,
            options: .init(sessionId: .new())
        )
        self.clientId = userPool.appClientId
        self.configuration = configuration
        self.signUp = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: userPool.region)
        )
    }

    func signUpAndSignIn(username: String, password: String, email: String, signedUp: @MainActor () -> Void) async throws {
        // Fresh users come from the raw SignUp, not from the API under test.
        do {
            _ = try await signUp.signUp(input: SignUpInput(
                clientId: clientId,
                password: password,
                userAttributes: [.init(name: "email", value: email)],
                username: username
            ))
        } catch {
            throw HarnessAppError.selfSignUpRefusal(error)
        }
        signedUp()
        let result = try await client.signIn(
            username: username,
            password: password,
            options: AuthClientSignInOptions(authFlowType: .userPassword)
        )
        guard result.nextStep == .done else {
            throw HarnessAppError("Password sign-in stopped at \(result.nextStep)")
        }
    }

    func signInWithWebAuthn(username: String, presentationAnchor: ASPresentationAnchor) async throws {
        let result = try await client.signIn(
            username: username,
            presentationAnchor: presentationAnchor,
            options: AuthClientSignInOptions(authFlowType: .userAuth(preferredFirstFactor: .webAuthn))
        )
        guard result.nextStep == .done else {
            throw HarnessAppError("WebAuthn sign-in stopped at \(result.nextStep)")
        }
    }

    /// The sign-out never throws: `.failed` is the session still signed in, and is thrown here so the screen
    /// says so and stays signed in. `.partial` signed it out on this device, as the plugin's app reads it.
    func signOut() async throws -> String {
        // The row is purged, not kept: this app shares its keychain with the plugin's AuthWebAuthnApp.
        let result = await client.signOut(options: AuthClientSignOutOptions(purgeStoredSession: true))
        switch result {
        case .complete:
            return "User is signed out"
        case .partial:
            return "User is signed out, but part of it failed: \(result.failedParts)"
        case .failed(let error):
            // By case name only: an error's text or payload can hold a username or an identifier.
            throw HarnessAppError("Sign-out left the user signed in: \(error.harnessCaseName)")
        }
    }

    func associateWebAuthnCredential(presentationAnchor: ASPresentationAnchor) async throws {
        try await client.associateWebAuthnCredential(presentationAnchor: presentationAnchor)
    }

    func listWebAuthnCredentials() async throws -> [String] {
        try await client.listWebAuthnCredentials().credentials.map(\.credentialId)
    }

    func deleteWebAuthnCredential(credentialId: String) async throws {
        try await client.deleteWebAuthnCredential(credentialId: credentialId)
    }

    func deleteUser(username: String, password: String) async throws {
        do {
            try await client.deleteUser()
        } catch AuthClientError.notSignedIn {
            _ = try await client.signIn(
                username: username,
                password: password,
                options: AuthClientSignInOptions(authFlowType: .userPassword)
            )
            try await client.deleteUser()
        }
        // Leave no row behind in the keychain the plugin's app also reads.
        try await AmplifyCognitoClient.purgeStoredSession(sessionId: client.sessionId, configuration: configuration)
    }

    /// The client stops its ceremony when the calling task is cancelled, and the
    /// app cancels that task alongside this call.
    func cancelCeremony() {}
}
#endif
