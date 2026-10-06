//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A multi-factor authentication type.
///
/// Mirrors Amplify core's `MFAType` case for case, with the same raw values.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientMFAType: String {

    /// Short Messaging Service linked with a phone number
    case sms

    /// Time-based One Time Password linked with an authenticator app
    case totp

    /// Email Service linked with an email
    case email
}

@_spi(AmplifyExperimental)
public extension AuthClientMFAType {

    /// The value to pass as `confirmSignIn`'s `challengeResponse` to choose this type, at an MFA
    /// selection (`continueSignInWithMFASelection`) or an MFA setup selection
    /// (`continueSignInWithMFASetupSelection`): Cognito's `SMS_MFA`, `SOFTWARE_TOKEN_MFA` or
    /// `EMAIL_OTP`. It mirrors the plugin's `MFAType.challengeResponse`.
    ///
    /// `rawValue` is not a valid challenge response. It stays Amplify core's (`sms`, `totp`, `email`), and
    /// an MFA selection refuses it. The plugin's module redefines `rawValue` as the Cognito string; the
    /// client does not.
    var challengeResponse: String {
        switch self {
        case .sms:
            return "SMS_MFA"
        case .totp:
            return "SOFTWARE_TOKEN_MFA"
        case .email:
            return "EMAIL_OTP"
        }
    }
}

extension AuthClientMFAType: Sendable {}
