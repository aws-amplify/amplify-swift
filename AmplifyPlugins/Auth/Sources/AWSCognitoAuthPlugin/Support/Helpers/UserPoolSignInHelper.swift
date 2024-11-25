//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

struct UserPoolSignInHelper: DefaultLogger {

    static func checkNextStep(
        _ signInState: SignInState
    ) throws -> AuthSignInResult? {
        log.verbose("Checking next step for: \(signInState)")

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
            return .init(nextStep: signInStep)

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
            throw signInError.authError
        }
    }

    static func sendRespondToAuth(
        request: RespondToAuthChallengeInput,
        for username: String,
        signInMethod: SignInMethod,
        environment: UserPoolEnvironment) async throws -> StateMachineEvent {

            let client = try environment.cognitoUserPoolFactory()
            let response = try await client.respondToAuthChallenge(input: request)
            let event = self.parseResponse(response, for: username, signInMethod: signInMethod)
            return event
        }

    static func parseResponse(
        _ response: SignInResponseBehavior,
        for username: String,
        signInMethod: SignInMethod,
        presentationAnchor: AuthUIPresentationAnchor? = nil,
        srpStateData: SRPStateData? = nil
    ) -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {
                let userPoolTokens = AWSCognitoUserPoolTokens(
                    idToken: idToken,
                    accessToken: accessToken,
                    refreshToken: refreshToken,
                    expiresIn: authenticationResult.expiresIn)
                let signedInData = SignedInData(
                    signedInDate: Date(),
                    signInMethod: signInMethod,
                    deviceMetadata: authenticationResult.deviceMetadata,
                    cognitoUserPoolTokens: userPoolTokens)

                switch signedInData.deviceMetadata {
                case .noData:
                    return SignInEvent(eventType: .finalizeSignIn(signedInData))
                case .metadata:
                    return SignInEvent(eventType: .confirmDevice(signedInData))
                }

            } else if let challengeName = response.challengeName {
                let parameters = response.challengeParameters
                let respondToAuthChallenge = RespondToAuthChallenge(
                    challenge: challengeName,
                    availableChallenges: response.availableChallenges ?? [],
                    username: username,
                    session: response.session,
                    parameters: parameters)

                switch challengeName {
                case .smsMfa, .customChallenge, .newPasswordRequired, .softwareTokenMfa, .selectMfaType, .smsOtp, .emailOtp, .selectChallenge:
                    return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                case .passwordVerifier:
                    guard let srpStateData else {
                        let message = "Unable to extract SRP state data to continue with password verification."
                        let error = SignInError.invalidServiceResponse(message: message)
                        return SignInEvent(eventType: .throwAuthError(error))
                    }
                    return SignInEvent(
                        eventType: .respondPasswordVerifier(srpStateData, response, [:])
                    )
                case .deviceSrpAuth:
                    return SignInEvent(eventType: .initiateDeviceSRP(username, response))
                case .webAuthn:
                    let signInData = WebAuthnSignInData(
                        username: username,
                        presentationAnchor: presentationAnchor
                    )
                    return SignInEvent(eventType: .initiateWebAuthnSignIn(signInData, respondToAuthChallenge))
                case .mfaSetup:
                    let allowedMFATypesForSetup = respondToAuthChallenge.getAllowedMFATypesForSetup
                    if allowedMFATypesForSetup.contains(.totp) && allowedMFATypesForSetup.contains(.email) {
                        return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                    } else if allowedMFATypesForSetup.contains(.totp) {
                        return SignInEvent(eventType: .initiateTOTPSetup(username, respondToAuthChallenge))
                    } else if allowedMFATypesForSetup.contains(.email) {
                        return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                    } else {
                        let message = "Cannot initiate MFA setup from available Types: \(allowedMFATypesForSetup)"
                        let error = SignInError.invalidServiceResponse(message: message)
                        return SignInEvent(eventType: .throwAuthError(error))
                    }
                default:
                    let message = "Unsupported challenge response \(challengeName)"
                    let error = SignInError.unknown(message: message)
                    return SignInEvent(eventType: .throwAuthError(error))
                }
            } else {
                let message = "Response did not contain signIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                return SignInEvent(eventType: .throwAuthError(error))
            }
        }
}
