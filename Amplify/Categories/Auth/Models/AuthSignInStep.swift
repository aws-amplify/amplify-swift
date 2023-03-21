//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A unique generated shared secret code that is used in the TOTP algorithm to generate a one-time code.
public typealias SharedSecretCode = String

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

    /// Auth step is Software Token multi factor authentication.
    ///
    case confirmSignInWithSoftwareToken(AdditionalInfo?)

    /// Auth step is for setting up Software Token multi factor authentication.
    ///
    case setupTOTPMFAWithSecretCode(SharedSecretCode, AdditionalInfo?)

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
