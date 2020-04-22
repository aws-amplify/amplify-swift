//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthSignInResult {

    /// Informs whether the user is signedIn or not.
    ///
    /// When this value is false, it means that there are more steps to follow for the signIn flow. Check `nextStep`
    /// to understand the next flow. If `isSignedIn` is true, signIn flow has been completed.
    public var isSignedIn: Bool {
        nextStep == .done
    }

    /// Shows the next step required to complete the signIn flow.
    ///
    public var nextStep: AuthSignInStep

    //TODO: Add Code delivery #172336364

    public init(nextStep: AuthSignInStep) {
        self.nextStep = nextStep
    }
}

/// Auth SignIn flow steps
public enum AuthSignInStep {

    /// Auth step is SMS multi factor authentication.
    ///
    /// Confirmation code for the MFA will be send to the provided SMS.
    case smsMFAChallenge

    /// Auth step is in a custom challenge depending on the plugin.
    ///
    case customChallenge

    /// Auth step required the user to give their password.
    ///
    case passwordChallenge

    /// Auth step is TOTP multi factor authentication.
    ///
    /// Confirmation code for the MFA will be software token.
    case softwareTokenMFAChallenge

    /// Auth step required the user to change their password.
    ///
    case newPasswordRequiredChallenge

    /// Auth step require the user to setup their MFA preferences
    ///
    case mfaSetup

    /// There is no next step and the signIn flow is complete
    ///
    case done
}
