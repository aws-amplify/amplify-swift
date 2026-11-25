//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Why a local WebAuthn ceremony (the passkey sheet) failed. Carried by
/// `AmplifyCognitoClientError.webAuthnCeremonyFailed`, whose underlying error is the platform's
/// `ASAuthorizationError` for `.credentialAlreadyExists` and `.failed`, and an internal encoding or decoding
/// error, which an app cannot name, for `.invalidCredential`.
///
/// Distinct from Cognito's answers, which are `AmplifyCognitoClientError.service` with a WebAuthn
/// `AmplifyCognitoClientServiceErrorCode`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AmplifyCognitoClientWebAuthnCeremonyFailure {

    /// Registration matched a credential the user already has (`ASAuthorizationError` code 1006).
    case credentialAlreadyExists

    /// The platform could not complete the ceremony.
    case failed

    /// The ceremony's options could not be read, or its result could not be encoded for Cognito.
    case invalidCredential
}

extension AmplifyCognitoClientWebAuthnCeremonyFailure: Equatable {}

extension AmplifyCognitoClientWebAuthnCeremonyFailure: Hashable {}

extension AmplifyCognitoClientWebAuthnCeremonyFailure: Sendable {}
