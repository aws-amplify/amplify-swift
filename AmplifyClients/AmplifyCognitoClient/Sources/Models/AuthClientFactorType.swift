//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A factor that can be used to sign in.
///
/// Mirrors Amplify core's `AuthFactorType` case for case, with the same raw values and the same
/// platform and availability conditions on `webAuthn`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientFactorType: String {

    /// An auth factor that uses password
    case password

    /// An auth factor that uses SRP protocol
    case passwordSRP

    /// An auth factor that uses SMS OTP
    case smsOTP

    /// An auth factor that uses Email OTP
    case emailOTP

    #if os(iOS) || os(macOS) || os(visionOS)
    /// An auth factor that uses WebAuthn
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    case webAuthn
    #endif
}

extension AuthClientFactorType: Sendable {}

@_spi(AmplifyExperimental)
public extension AuthClientFactorType {

    /// The answer that selects this factor at `.continueSignInWithFirstFactorSelection`, for
    /// `confirmSignIn(challengeResponse:options:)`: Cognito's name for it, such as `"PASSWORD_SRP"`. The
    /// plugin's `AuthFactorType.challengeResponse`.
    ///
    /// `webAuthn`'s `"WEB_AUTHN"` shows the passkey sheet over the window given to
    /// `confirmSignIn(challengeResponse:presentationAnchor:options:)`, else the one given to the anchored
    /// `signIn`. With no window at all it is refused with `.validation(field: "presentationAnchor")` before
    /// anything is sent, and the selection stays pending.
    var challengeResponse: String {
        switch self {
        case .password: return "PASSWORD"
        case .passwordSRP: return "PASSWORD_SRP"
        case .smsOTP: return "SMS_OTP"
        case .emailOTP: return "EMAIL_OTP"
        #if os(iOS) || os(macOS) || os(visionOS)
        case .webAuthn: return "WEB_AUTHN"
        #endif
        }
    }
}
