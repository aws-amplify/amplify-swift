//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

// The account-operation requests and results as the engine receives and returns them.
// Public inputs are mapped here once, by the facade, so every engine gets Cognito's names.
//
// **An empty dictionary means none.** The public options default `validationData`, `clientMetadata` and the
// user attributes to `[:]` / `[]` where the plugin's are `nil`. The live engine must send an empty one as
// omitted (`nil` on the SDK input, as the plugin's `nil` options do), never as an empty map: a Lambda trigger
// may treat an empty `ClientMetadata` differently from none.

/// A sign-up, as the engine receives it.
struct EngineSignUpRequest: Sendable, Equatable {
    let username: String
    let password: String?
    /// Cognito attribute names (`email`, `custom:team`, ...), mapped from `AuthClientUserAttributeKey`.
    let userAttributes: [String: String]
    let validationData: [String: String]
    let clientMetadata: [String: String]
}

/// A sign-up confirmation, as the engine receives it.
struct EngineConfirmSignUpRequest: Sendable, Equatable {
    let username: String
    let confirmationCode: String
    let clientMetadata: [String: String]
    let forceAliasCreation: Bool?
}

/// A password-reset confirmation, as the engine receives it.
struct EngineConfirmResetPasswordRequest: Sendable, Equatable {
    let username: String
    let newPassword: String
    let confirmationCode: String
    let clientMetadata: [String: String]
}

/// A federation to the identity pool, as the engine receives it.
struct EngineFederationRequest: Sendable, Equatable {
    let token: String
    let provider: AuthClientProvider
    let developerProvidedIdentityId: String?
}

/// What a step that may start a WebAuthn ceremony needs: the window, and the runner that takes the
/// process-wide sheet lease for this session around the ceremony.
///
/// One per call: the core makes it (`SystemSheetFlow.ceremonyContext`), and a sign-in step that runs no ceremony ignores it.
struct EngineCeremonyContext: Sendable {
    /// The window, or `nil` when the call was given none: a WebAuthn step then fails with
    /// `.validation(field: "presentationAnchor")` without presenting. A confirmation without one uses the
    /// window its sign-in was given.
    let anchor: EnginePresentationAnchorBox?
    /// Takes the sheet lease for this session and runs `body` (one ceremony) under it: the engine's
    /// `WebAuthnCredentialOperations.CeremonyRunner`, so it passes straight through.
    let ceremony: WebAuthnCredentialOperations.CeremonyRunner
    /// Stops this call's ceremony: cancels one in flight (the kept controller closes the sheet), and refuses
    /// one not started yet. What the engine's `cancelPendingSignIn` calls for a sign-in step's ceremony,
    /// which runs in an effect task nothing else can reach. Idempotent.
    var cancel: @Sendable () -> Void = {}
}

extension EngineCeremonyContext: Equatable {
    /// The same window. The runner is a closure, which cannot be compared.
    static func == (lhs: EngineCeremonyContext, rhs: EngineCeremonyContext) -> Bool {
        lhs.anchor == rhs.anchor
    }
}
