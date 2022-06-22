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
            if signInError.isUserUnConfirmed {
                return .success(AuthSignInResult(nextStep: .confirmSignUp(nil)))
            } else if signInError.isResetPassword {
                return .success(AuthSignInResult(nextStep: .resetPassword(nil)))
            } else {
                return .failure(signInError.authError)
            }
        } else if case .resolvingSMSChallenge(let challengeState) = signInState,
                  case .waitingForAnswer(let challenge) = challengeState {
            let delivery = challenge.codeDeliveryDetails
            return .success(.init(nextStep: .confirmSignInWithSMSMFACode(delivery, nil)))
        }
        return nil
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
        _ response: RespondToAuthChallengeOutputResponse,
        for username: String) -> StateMachineEvent {

            if let authenticationResult = response.authenticationResult,
               let idToken = authenticationResult.idToken,
               let accessToken = authenticationResult.accessToken,
               let refreshToken = authenticationResult.refreshToken {

                let userPoolTokens = AWSCognitoUserPoolTokens(idToken: idToken,
                                                              accessToken: accessToken,
                                                              refreshToken: refreshToken,
                                                              expiresIn: authenticationResult.expiresIn)
                let signedInData = SignedInData(userId: "",
                                                userName: username,
                                                signedInDate: Date(),
                                                signInMethod: .srp,
                                                cognitoUserPoolTokens: userPoolTokens)
                return SignInEvent(eventType: .finalizeSRPSignIn(signedInData))

            } else if let challengeName = response.challengeName, let session = response.session {
                let parameters = response.challengeParameters
                let response = RespondToAuthChallenge(challenge: challengeName,
                                                      username: username,
                                                      session: session,
                                                      parameters: parameters)

                switch challengeName {
                case .smsMfa:
                    return SignInEvent(eventType: .receivedSMSChallenge(response))
                default:
                    let message = "UnSupported challenge response \(challengeName)"
                    let error = SignInError.invalidServiceResponse(message: message)
                    return SignInEvent(eventType: .throwPasswordVerifierError(error))
                }
            } else {
                let message = "Response did not contain signIn info"
                let error = SignInError.invalidServiceResponse(message: message)
                return SignInEvent(eventType: .throwPasswordVerifierError(error))
            }
        }
}
