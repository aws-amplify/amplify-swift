//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of `Amplify.AuthSignInStep`: the same 14 cases, in the same order, with each
/// payload replaced by its engine mirror.
///
/// | `AuthSignInStep` payload | Engine payload |
/// |---|---|
/// | `AuthCodeDeliveryDetails` | `EngineCodeDeliveryDetails` |
/// | `AdditionalInfo` (`[String: String]`) | `[String: String]` |
/// | `TOTPSetupDetails` | `EngineTOTPSetupDetails` |
/// | `AllowedMFATypes` (`Set<MFAType>`) | `Set<EngineMFAType>` |
/// | `AvailableAuthFactorTypes` (`Set<AuthFactorType>`) | `Set<EngineAuthFactorType>` |
///
/// `Equatable` is synthesized, as on the public type. The plugin maps it to `AuthSignInStep`, case to
/// case, in `AWSCognitoAuthPlugin/Support/EngineBridge/AuthSignInStep+Engine.swift`. The client maps it
/// to its own step type.
package enum EngineSignInStep {

    /// Auth step is SMS multi factor authentication.
    case confirmSignInWithSMSMFACode(EngineCodeDeliveryDetails, [String: String]?)

    /// Auth step is in a custom challenge depending on the plugin.
    case confirmSignInWithCustomChallenge([String: String]?)

    /// Auth step required the user to give a new password.
    case confirmSignInWithNewPassword([String: String]?)

    /// Auth step requires user to enter the password.
    case confirmSignInWithPassword

    /// Auth step is TOTP multi factor authentication.
    case confirmSignInWithTOTPCode

    /// Auth step is for continuing sign in by setting up TOTP multi factor authentication.
    case continueSignInWithTOTPSetup(EngineTOTPSetupDetails)

    /// Auth step is for continuing sign in by selecting multi factor authentication type.
    case continueSignInWithMFASelection(Set<EngineMFAType>)

    /// Auth step is for continuing sign in by setting up EMAIL multi factor authentication.
    case continueSignInWithEmailMFASetup

    /// Auth step is for continuing sign in by selecting multi factor authentication type to setup.
    case continueSignInWithMFASetupSelection(Set<EngineMFAType>)

    /// Auth step is for confirming sign in with OTP.
    case confirmSignInWithOTP(EngineCodeDeliveryDetails)

    /// Auth step is for continuing sign in by selecting the first factor that would be used for signing in.
    case continueSignInWithFirstFactorSelection(Set<EngineAuthFactorType>)

    /// Auth step required the user to change their password.
    case resetPassword([String: String]?)

    /// Auth step that required the user to be confirmed.
    case confirmSignUp([String: String]?)

    /// There is no next step and the sign in flow is complete.
    case done
}

extension EngineSignInStep: Equatable { }

extension EngineSignInStep: Sendable { }

/// The engine's copy of `Amplify.TOTPSetupDetails`'s stored values. `getSetupURI(appName:accountName:)`
/// stays on the public type: nothing in the engine builds the URI.
package struct EngineTOTPSetupDetails {

    /// Secret code returned by the service to help setting up TOTP
    package let sharedSecret: String

    /// username that will be used to construct the URI
    package let username: String

    package init(sharedSecret: String, username: String) {
        self.sharedSecret = sharedSecret
        self.username = username
    }
}

extension EngineTOTPSetupDetails: Equatable { }

extension EngineTOTPSetupDetails: Sendable { }
