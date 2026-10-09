//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The next step of a multi-step sign-in.
///
/// Mirrors Amplify core's `AuthSignInStep` case for case, with the same associated-value shapes,
/// using client-owned payload types in place of Amplify core's. The client does not depend on
/// Amplify core, so the plugin bridge maps between the two. Amplify core's typealiases are
/// spelled out: `AdditionalInfo` is `[String: String]`, `AllowedMFATypes` is
/// `Set<AuthClientMFAType>` and `AvailableAuthFactorTypes` is `Set<AuthClientFactorType>`.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientSignInStep {

    /// Auth step is SMS multi factor authentication.
    ///
    /// Confirmation code for the MFA will be send to the provided SMS.
    case confirmSignInWithSMSMFACode(AuthClientCodeDeliveryDetails, [String: String]?)

    /// Auth step is in a custom challenge.
    ///
    case confirmSignInWithCustomChallenge([String: String]?)

    /// Auth step required the user to give a new password.
    ///
    case confirmSignInWithNewPassword([String: String]?)

    /// Auth step required the user to give a password.
    ///
    case confirmSignInWithPassword

    /// Auth step is TOTP multi factor authentication.
    ///
    /// Confirmation code for the MFA will be retrieved from the associated Authenticator app
    case confirmSignInWithTOTPCode

    /// Auth step is for continuing sign in by setting up TOTP multi factor authentication.
    ///
    case continueSignInWithTOTPSetup(AuthClientTOTPSetupDetails)

    /// Auth step is for continuing sign in by selecting multi factor authentication type
    ///
    case continueSignInWithMFASelection(Set<AuthClientMFAType>)

    /// Auth step is for continuing sign in by setting up EMAIL multi factor authentication.
    ///
    case continueSignInWithEmailMFASetup

    /// Auth step is for continuing sign in by selecting multi factor authentication type to setup
    ///
    case continueSignInWithMFASetupSelection(Set<AuthClientMFAType>)

    /// Auth step is for confirming sign in with OTP
    ///
    /// OTP for the factor will be sent to the delivery medium.
    case confirmSignInWithOTP(AuthClientCodeDeliveryDetails)

    /// Auth step is for continuing sign in by selecting the first factor that would be used for signing in
    ///
    case continueSignInWithFirstFactorSelection(Set<AuthClientFactorType>)

    /// Auth step required the user to change their password.
    ///
    case resetPassword([String: String]?)

    /// Auth step that required the user to be confirmed
    ///
    case confirmSignUp([String: String]?)

    /// There is no next step and the signIn flow is complete
    ///
    case done
}

extension AuthClientSignInStep: Equatable {}

extension AuthClientSignInStep: Sendable {}
