//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AuthenticationServices
import Foundation
import UIKit

/// What the harness screen's buttons do. One implementation per API under test: the raw Cognito
/// API (WA-0) and the client (WA-1). Both see the same screen, so the UI tests drive one flow.
@MainActor
protocol WebAuthnHarnessDriver: AnyObject {
    /// A name for the result line, so a failure says which driver ran.
    var name: String { get }

    /// Creates the user with the raw `SignUp` (fresh users never come from the API under test;
    /// the pool's pre-sign-up trigger confirms them), then signs in with its password. Calls `signedUp` as soon
    /// as the user exists, so a failed sign-in still leaves the user for the test to delete.
    func signUpAndSignIn(username: String, password: String, email: String, signedUp: @MainActor () -> Void) async throws

    /// Signs in with `USER_AUTH`, `WEB_AUTHN` as the preferred first factor: the passkey sheet.
    func signInWithWebAuthn(username: String, presentationAnchor: ASPresentationAnchor) async throws

    func signOut() async throws

    /// Registers a passkey for the signed-in user: the passkey sheet, then Face ID.
    func associateWebAuthnCredential(presentationAnchor: ASPresentationAnchor) async throws

    /// The signed-in user's credential IDs.
    func listWebAuthnCredentials() async throws -> [String]

    func deleteWebAuthnCredential(credentialId: String) async throws

    /// Deletes the user, signing in with its password first if the session is signed out, so a run that
    /// fails between sign-out and the passkey sign-in still removes its user.
    func deleteUser(username: String, password: String) async throws

    /// Stops the passkey ceremony in flight, if any, so the action that started it ends.
    func cancelCeremony()
}

@MainActor
enum WebAuthnHarness {

    /// The WebAuthn parity pool (U-WA)'s outputs file, copied into the app bundle at build time from
    /// `~/.amplify-cognito-client-integ` (the "Copy sandbox configuration" phase). Its WebAuthn relying
    /// party is the domain in `CognitoClientWebAuthnApp.entitlements` (infra/parity.py, P-10).
    static let outputsResource = "webauthn-amplify_outputs"

    static func configuration() throws -> AuthClientConfiguration {
        guard Bundle.main.url(forResource: outputsResource, withExtension: "json") != nil else {
            throw HarnessAppError("\(outputsResource).json is not in the app bundle. Run infra/provision.sh, then rebuild.")
        }
        return try AuthClientConfiguration(from: outputsResource, bundle: .main)
    }

    static func makeDriver() -> Result<WebAuthnHarnessDriver, HarnessAppError> {
        let arguments = ProcessInfo.processInfo.arguments
        let selected = arguments.firstIndex(of: "-WebAuthnDriver").flatMap { index in
            arguments.indices.contains(index + 1) ? arguments[index + 1] : nil
        } ?? "raw"
        do {
            switch selected {
            case "raw":
                return try .success(RawSDKWebAuthnDriver(configuration: configuration()))
            case "client":
                #if COGNITO_CLIENT_WEBAUTHN_API
                return try .success(ClientWebAuthnDriver(configuration: configuration()))
                #else
                return .failure(HarnessAppError(
                    "The client driver needs the Phase 5 WebAuthn API: build with COGNITO_CLIENT_WEBAUTHN_API (CognitoClientWebAuthn.xcconfig)."
                ))
                #endif
            default:
                return .failure(HarnessAppError("Unknown -WebAuthnDriver \(selected); use raw or client."))
            }
        } catch {
            return .failure(HarnessAppError("Could not configure the \(selected) driver: \(error)"))
        }
    }

    /// The window the passkey sheet attaches to. The app passes it explicitly: the client's API takes
    /// a non-optional anchor, so this is also what an app is expected to do.
    static func keyWindow() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        if let window = active?.keyWindow ?? active?.windows.first {
            return window
        }
        preconditionFailure("The harness app has no window to present the passkey sheet on")
    }
}

struct HarnessAppError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
