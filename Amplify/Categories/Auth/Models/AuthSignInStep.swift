//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Set of allowed MFA types that would be used for continuing sign in during MFA selection step
public typealias AllowedMFATypes = Set<MFAType>

/// Set of available factors that would be used for continuing/confirming sign in
public typealias AvailableAuthFactorTypes = Set<AuthFactorType>

/// Auth SignIn flow steps
///
///
public enum AuthSignInStep {

    /// Auth step is SMS multi factor authentication.
    ///
    /// Confirmation code for the MFA will be send to the provided SMS.
    case confirmSignInWithSMSMFACode(AuthCodeDeliveryDetails, AdditionalInfo?)

    /// Auth step is in a custom challenge depending on the plugin.
    ///
    case confirmSignInWithCustomChallenge(AdditionalInfo?)

    /// Auth step required the user to give a new password.
    ///
    case confirmSignInWithNewPassword(AdditionalInfo?)

    /// Auth step required the user to give a password.
    ///
    case confirmSignInWithPassword

    /// Auth step is TOTP multi factor authentication.
    ///
    /// Confirmation code for the MFA will be retrieved from the associated Authenticator app
    case confirmSignInWithTOTPCode

    /// Auth step is for continuing sign in by setting up TOTP multi factor authentication.
    ///
    case continueSignInWithTOTPSetup(TOTPSetupDetails)

    /// Auth step is for continuing sign in by selecting multi factor authentication type
    ///
    case continueSignInWithMFASelection(AllowedMFATypes)

    /// Auth step is for continuing sign in by setting up EMAIL multi factor authentication.
    ///
    case continueSignInWithEmailMFASetup

    /// Auth step is for continuing sign in by selecting multi factor authentication type to setup
    ///
    case continueSignInWithMFASetupSelection(AllowedMFATypes)

    /// Auth step is for confirming sign in with OTP
    ///
    /// OTP for the factor will be sent to the delivery medium.
    case confirmSignInWithOTP(AuthCodeDeliveryDetails)

    /// Auth step is for continuing sign in by selecting the first factor that would be used for signing in
    ///
    case continueSignInWithFirstFactorSelection(AvailableAuthFactorTypes)

    /// Auth step required the user to change their password.
    ///
    case resetPassword(AdditionalInfo?)

    /// Auth step that required the user to be confirmed
    ///
    case confirmSignUp(AdditionalInfo?)

    /// There is no next step and the signIn flow is complete
    ///
    case done
}

extension AuthSignInStep: Equatable { }

extension AuthSignInStep: Sendable { }
