//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthConfirmSignInTask: AuthConfirmSignInTask {

    private let request: AuthConfirmSignInRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInAPI
    }

    init(_ request: AuthConfirmSignInRequest, stateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = stateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignInResult {
        if let validationError = request.hasError() {
            throw validationError
        }
        let invalidStateError = AuthError.invalidState(
            "User is not attempting signIn operation",
            AuthPluginErrorConstants.invalidStateError, nil)

        await taskHelper.didStateMachineConfigured()

        if case .configured(let authNState, _) = await authStateMachine.currentState,
           case .signingIn(let signInState) = authNState,
           case .resolvingChallenge(let challengeState, _, _) = signInState,
           case .waitingForAnswer = challengeState {
            await sendConfirmSignInEvent()
        }

        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
               guard case .configured(let authNState, let authZState) = state else {
                   continue
               }
               switch authNState {
               case .signedIn:
                   if case .sessionEstablished = authZState {
                       return AuthSignInResult(nextStep: .done)
                   }
               case .error(let error):
                   throw AuthError.unknown("Sign in reached an error state", error)

               case .signingIn(let signInState):
                   if case .resolvingChallenge(let challengeState, _, _) = signInState,
                      case .error(_, let signInError) = challengeState {
                       let authError = signInError.authError
                       if authError.type == AuthError.serviceError,
                          let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                          case .passwordResetRequired = cognitoError {
                           return AuthSignInResult(nextStep: .resetPassword(nil))

                       } else if authError.type == AuthError.serviceError,
                           let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                                 case .userNotConfirmed = cognitoError {
                           return AuthSignInResult(nextStep: .confirmSignUp(nil))
                       } else {
                           throw authError
                       }
                   } else if case .resolvingChallenge(let challengeState, _, _) = signInState {
                       switch challengeState {
                       case .waitingForAnswer:
                           guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                               continue
                           }
                           return result

                       default:
                           continue
                       }
                   }
               case .notConfigured:
                   throw AuthError.configuration(
                    "UserPool configuration is missing",
                    AuthPluginErrorConstants.configurationError)
               default:
                   throw invalidStateError
               }
        }
        throw invalidStateError
    }

    func sendConfirmSignInEvent() async {
        let pluginOptions = (request.options.pluginOptions as? AWSAuthConfirmSignInOptions)

        // Convert the attributes to [String: String]
        let attributePrefix = AuthPluginConstants.cognitoIdentityUserUserAttributePrefix
        let attributes = pluginOptions?.userAttributes?.reduce(
            into: [String: String]()) {
                $0[attributePrefix + $1.key.rawValue] = $1.value
            } ?? [:]
        let confirmSignInData = ConfirmSignInEventData(
            answer: self.request.challengeResponse,
            attributes: attributes,
            metadata: pluginOptions?.metadata)
        let event = SignInChallengeEvent(
            eventType: .verifyChallengeAnswer(confirmSignInData))
        await authStateMachine.send(event)
    }

}
