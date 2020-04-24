//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Auth SignIn flow steps
public enum AuthSignInStep {

    /// Auth step is SMS multi factor authentication.
    ///
    /// Confirmation code for the MFA will be send to the provided SMS.
    case confirmSignInWithSMSMFACode

    /// Auth step is in a custom challenge depending on the plugin.
    ///
    case confirmSignInWithCustomChallenge

    /// Auth step required the user to give a new password.
    ///
    case confirmSignInWithNewPassword

    /// Auth step required the user to change their password.
    ///
    case resetPassword

    /// Auth step that required the user to be confirmed
    ///
    case confirmSignUp

    /// There is no next step and the signIn flow is complete
    ///
    case done
}
