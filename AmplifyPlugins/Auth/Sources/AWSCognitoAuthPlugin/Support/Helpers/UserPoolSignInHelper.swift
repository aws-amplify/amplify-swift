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
    -> Result<AuthSignInResult, AuthError>? {

        if case .signingInWithSRP(let srpState, _) = signInState,
           case .error(let signInError) = srpState {
            return validateError(signInError: signInError)
        } else if case .signingInWithSRPCustom(let srpState, _) = signInState,
                  case .error(let signInError) = srpState {
            return validateError(signInError: signInError)
        } else if case .signingInWithCustom(let customAuthState, _) = signInState,
                  case .error(let signInError) = customAuthState {
            return validateError(signInError: signInError)
        } else if case .resolvingChallenge(let challengeState, let challengeType) = signInState,
                  case .waitingForAnswer(let challenge) = challengeState {
            return validateResult(for: challengeType, with: challenge)
        } else if case .signingInWithHostedUI(let hostedUIState) = signInState,
                  case .error(let hostedUIError) = hostedUIState {
            return validateError(signInError: hostedUIError)
        }
        return nil
    }

    private static func validateResult(for challengeType: AuthChallengeType, with challenge: RespondToAuthChallenge) -> Result<AuthSignInResult, AuthError> {
        switch challengeType {
        case .smsMfa:
            let delivery = challenge.codeDeliveryDetails
            return .success(.init(nextStep: .confirmSignInWithSMSMFACode(delivery, challenge.parameters)))
        case .customChallenge:
            return .success(.init(nextStep: .confirmSignInWithCustomChallenge(challenge.parameters)))
        case .newPasswordRequired:
            return .success(.init(nextStep: .confirmSignInWithNewPassword(challenge.parameters)))
        case .unknown:
            return .failure(.unknown("Challenge not supported", nil))
        }
    }

    private static func validateError(signInError: SignInError) -> Result<AuthSignInResult, AuthError> {
        if signInError.isUserUnConfirmed {
            return .success(AuthSignInResult(nextStep: .confirmSignUp(nil)))
        } else if signInError.isResetPassword {
            return .success(AuthSignInResult(nextStep: .resetPassword(nil)))
        } else {
            return .failure(signInError.authError)
        }
    }

    static func sendRespondToAuth(request: RespondToAuthChallengeInput,
                                  for username: String,
                                  environment: UserPoolEnvironment,
                                  callback: @escaping (StateMachineEvent) -> Void) throws {

        let client = try environment.cognitoUserPoolFactory()

        Task {
            do {
                let response = try await client.respondToAuthChallenge(input: request)
                callback(self.parseResponse(response, for: username))
            } catch {
                let authError = SignInError.service(error: error)
                callback(SignInEvent(eventType: .throwAuthError(authError)))
            }
        }
    }

    static func parseResponse(
        _ response: SignInResponseBehavior,
        for username: String) -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {

                let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
                                                              accessToken: accessToken,
                                                              refreshToken: refreshToken,
                                                              expiresIn: authenticationResult.expiresIn)
                let signedInData = SignedInData(
                    userId: "",
                    userName: username,
                    signedInDate: Date(),
                    // TODO: remove hardcoded sign in method
                    signInMethod: .apiBased(.userSRP),
                    deviceMetadata: authenticationResult.deviceMetadata,
                    cognitoUserPoolTokens: userPoolTokens)

                switch signedInData.deviceMetadata {
                case .noData:
                    return SignInEvent(eventType: .finalizeSignIn(signedInData))
                case .metadata:
                    return SignInEvent(eventType: .confirmDevice(signedInData))
                }


            } else if let challengeName = response.challengeName, let session = response.session {
                let parameters = response.challengeParameters
                let response = RespondToAuthChallenge(challenge: challengeName,
                                                      username: username,
                                                      session: session,
                                                      parameters: parameters)

                switch challengeName {
                case .smsMfa, .customChallenge, .newPasswordRequired:
                    return SignInEvent(eventType: .receivedChallenge(response))
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
