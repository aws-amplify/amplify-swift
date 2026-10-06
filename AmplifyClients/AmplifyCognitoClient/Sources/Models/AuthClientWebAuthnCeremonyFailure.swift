//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Why a local WebAuthn ceremony (the passkey sheet) failed. Carried by
/// `AuthClientError.webAuthnCeremonyFailed`, whose underlying error is the platform's
/// `ASAuthorizationError`.
///
/// Distinct from Cognito's answers, which are `AuthClientError.service` with a WebAuthn
/// `AuthClientServiceErrorCode`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientWebAuthnCeremonyFailure {

    /// Registration matched a credential the user already has (`ASAuthorizationError` code 1006).
    case credentialAlreadyExists

    /// The platform could not complete the ceremony.
    case failed

    /// The ceremony's options could not be read, or its result could not be encoded for Cognito.
    case invalidCredential
}

extension AuthClientWebAuthnCeremonyFailure: Equatable {}

extension AuthClientWebAuthnCeremonyFailure: Hashable {}

extension AuthClientWebAuthnCeremonyFailure: Sendable {}
