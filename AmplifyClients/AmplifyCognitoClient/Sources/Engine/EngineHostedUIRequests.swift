//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// The hosted-UI requests as the engine receives them. Defined on every
// platform, so the seam has one shape; only iOS, macOS and visionOS build them, from `WebUIOptions`.

/// A hosted-UI sign-in, as the engine receives it.
struct EngineWebUISignInRequest: Sendable, Equatable {
    /// The window the browser attaches to. Weak: empty once the window has gone.
    let anchor: EnginePresentationAnchorBox
    let options: EngineWebUIOptions
    /// What the returned user must be. The token claims are always verified besides.
    let identity: EngineIdentityPolicy
}

/// The eight `WebUIOptions` fields the engine's `HostedUIOptions` carries. `whenBrowserBusy` and
/// `identityExpectation` are the core's, not the engine's.
struct EngineWebUIOptions: Sendable, Equatable {
    /// `nil` requests the configuration's scopes.
    let scopes: [String]?
    let provider: AuthClientProvider?
    /// Wins over `provider` (the plugin's precedence).
    let idpIdentifier: String?
    let prefersEphemeralSession: Bool
    /// Never `nil`: the core mints one when the caller gave none, so the ID token can be bound to the flow.
    let nonce: String
    let language: String?
    let loginHint: String?
    /// Space-separated, in the caller's order; `nil` for none, and for an empty list, which sends no `prompt`
    /// item (the `authorizeQueryItems` rule).
    let prompt: String?
    let resource: String?
}

/// What a hosted-UI sign-in's returned user must be (the engine's `HostedUIIdentityPolicy`, less its
/// `verifiesTokenClaims`, which the client always sets).
struct EngineIdentityPolicy: Sendable, Equatable {
    /// The returned user's `sub` or username must equal it.
    var expectedIdentity: String?
    /// The returned `sub` must not be one of these: the other signed-in sessions' users.
    var excludedSubjects: Set<String> = []

    static let none = EngineIdentityPolicy()
}

/// Whether a sign-out shows the hosted UI's logout page first.
enum EngineHostedUISignOut: Sendable, Equatable {
    /// No browser, whatever the sign-in was.
    case skip
    /// The logout page in this window, when the sign-in shared the browser's cookies.
    case present(EnginePresentationAnchorBox)
}

#if os(iOS) || os(macOS) || os(visionOS)
extension EngineWebUIOptions {

    /// `options` as the engine takes them, with `nonce` for the flow: the caller's, else a minted one.
    init(_ options: WebUIOptions, nonce: String) {
        self.init(
            scopes: options.scopes,
            provider: options.provider,
            idpIdentifier: options.idpIdentifier,
            prefersEphemeralSession: options.prefersEphemeralSession,
            nonce: nonce,
            language: options.language,
            loginHint: options.loginHint,
            prompt: options.prompt.flatMap { $0.isEmpty ? nil : $0.map(\.rawValue).joined(separator: " ") },
            resource: options.resource
        )
    }
}
#endif
