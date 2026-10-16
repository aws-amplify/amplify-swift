//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import InternalAWSCognitoAuth

/// The glue half of `UserPoolSignInHelper`: the next `AuthSignInResult` for a sign-in state. It converts the
/// engine's step and error at the boundary. The engine half is `UserPoolSignInHelper.swift`.
extension UserPoolSignInHelper {

    static func checkNextStep(
        _ signInState: SignInState
    ) throws -> AuthSignInResult? {
        EngineLog.logger(.category("UserPoolSignInHelper")).verbose("Checking next step for: \(signInState)")

        if case .signingInWithSRP(let srpState, _) = signInState,
           case .error(let signInError) = srpState {
            return try validateError(signInError: signInError)

        } else if case .signingInWithSRPCustom(let srpState, _) = signInState,
                  case .error(let signInError) = srpState {
            return try validateError(signInError: signInError)

        } else if case .signingInViaMigrateAuth(let migratedAuthState, _) = signInState,
                  case .error(let signInError) = migratedAuthState {
            return try validateError(signInError: signInError)

        } else if case .signingInWithCustom(let customAuthState, _) = signInState,
                  case .error(let signInError) = customAuthState {
            return try validateError(signInError: signInError)

        } else if case .signingInWithHostedUI(let hostedUIState) = signInState,
                  case .error(let hostedUIError) = hostedUIState {
            return try validateError(signInError: hostedUIError)

        } else if case .resolvingChallenge(let challengeState, _, _) = signInState,
                  case .error(_, _, let signInError, _) = challengeState {
            return try validateError(signInError: signInError)

        } else if case .resolvingChallenge(let challengeState, _, _) = signInState,
                  case .waitingForAnswer(_, _, let signInStep) = challengeState {
            return .init(nextStep: AuthSignInStep(signInStep))

        } else if case .resolvingTOTPSetup(let totpSetupState, _) = signInState,
                  case .error(_, let signInError) = totpSetupState {
            return try validateError(signInError: signInError)

        } else if case .resolvingTOTPSetup(let totpSetupState, _) = signInState,
                  case .waitingForAnswer(let totpSetupData) = totpSetupState {
            return .init(nextStep: .continueSignInWithTOTPSetup(
                .init(sharedSecret: totpSetupData.secretCode, username: totpSetupData.username)))
        } else if case .signingInWithWebAuthn(let webAuthnState) = signInState,
                  case .error(let signInError, _) = webAuthnState {
            return try validateError(signInError: signInError)
        }
        return nil
    }

    private static func validateError(signInError: SignInError) throws -> AuthSignInResult {
        if signInError.isUserNotConfirmed {
            return AuthSignInResult(nextStep: .confirmSignUp(nil))
        } else if signInError.isResetPassword {
            return AuthSignInResult(nextStep: .resetPassword(nil))
        } else {
            throw AuthError(signInError.engineError)
        }
    }
}
