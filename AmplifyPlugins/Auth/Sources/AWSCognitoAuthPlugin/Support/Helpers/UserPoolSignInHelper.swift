//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

struct UserPoolSignInHelper {

    static func checkNextStep(_ signInState: SignInState)
    throws -> AuthSignInResult? {

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
        } else if case .resolvingChallenge(let challengeState, let challengeType, _) = signInState,
                  case .waitingForAnswer(let challenge, _) = challengeState {
            return try validateResult(for: challengeType, with: challenge)
        } else if case .signingInWithHostedUI(let hostedUIState) = signInState,
                  case .error(let hostedUIError) = hostedUIState {
            return try validateError(signInError: hostedUIError)
        }
        return nil
    }

    private static func validateResult(for challengeType: AuthChallengeType,
                                       with challenge: RespondToAuthChallenge)
    throws -> AuthSignInResult {
        switch challengeType {
        case .smsMfa:
            let delivery = challenge.codeDeliveryDetails
            return .init(nextStep: .confirmSignInWithSMSMFACode(delivery, challenge.parameters))
        case .customChallenge:
            return .init(nextStep: .confirmSignInWithCustomChallenge(challenge.parameters))
        case .newPasswordRequired:
            return .init(nextStep: .confirmSignInWithNewPassword(challenge.parameters))
        case .unknown:
            throw AuthError.unknown("Challenge not supported", nil)
        }
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
            let event = try self.parseResponse(response, for: username, signInMethod: signInMethod)
            return event
        }



    static func parseResponse(
        _ response: SignInResponseBehavior,
        for username: String,
        signInMethod: SignInMethod) throws -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {

                let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
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
                    username: username,
                    session: response.session,
                    parameters: parameters)

                switch challengeName {
                case .smsMfa, .customChallenge, .newPasswordRequired:
                    return SignInEvent(eventType: .receivedChallenge(respondToAuthChallenge))
                case .deviceSrpAuth:
                    return SignInEvent(eventType: .initiateDeviceSRP(username, response))
                default:
                    let message = "UnSupported challenge response \(challengeName)"
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
