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
// **An empty dictionary means none, and each call sends none as the plugin does.** The public options default
// `validationData`, `clientMetadata` and the user attributes to `[:]` / `[]` where the plugin's are `nil`. The
// plugin does not send a `nil` option the same way on every call, and a Lambda trigger can tell an omitted
// `ClientMetadata` from an empty one, so the live engine follows it call by call:
// - omitted (`nil` on the SDK input): `signUp` and `confirmSignUp`, for client metadata and validation data
//   (`LiveSessionEngine.omittedIfEmpty`);
// - `[:]`: `signIn`, `resetPassword`, `confirmResetPassword`, `resendSignUpCode` and the attribute calls, which the
//   plugin's tasks send as `?? [:]`. `confirmSignIn` hands the engine `nil`, as the plugin's confirm task does
//   (`LiveSignInSteps.eventData(for:)`), and the engine fills in what goes on the wire as it does for the plugin
//   (`[:]` when it verifies an answer);
// - user attributes always as a list, `[]` for none.
// Pinned by `LiveEngineSignUpTests.testSignUpOmitsEmptyOptions` and `.testResendSignUpCodeSendsThePluginsRequest`,
// `LiveEngineSignInTests.testSignInWithoutClientMetadataSendsAnEmptyMap` and
// `.testConfirmSignInWithoutClientMetadataHandsTheEngineNone`, `LiveEngineResetPasswordTests` (both
// `SendsThePluginsRequest` tests), and `LiveEngineAttributesTests.testUpdateUserAttributesSendsThePluginsRequest` and
// `.testSendVerificationCode`.

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
