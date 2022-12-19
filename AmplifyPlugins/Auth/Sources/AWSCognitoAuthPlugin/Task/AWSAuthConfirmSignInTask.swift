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
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInAPI
    }

    init(_ request: AuthConfirmSignInRequest,
         stateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = stateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
    }

    func execute() async throws -> AuthSignInResult {

        await taskHelper.didStateMachineConfigured()

        //Check if we have a user pool configuration
        guard authConfiguration.getUserPoolConfiguration() != nil else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

        if let validationError = request.hasError() {
            throw validationError
        }
        let invalidStateError = AuthError.invalidState(
            "User is not attempting signIn operation",
            AuthPluginErrorConstants.invalidStateError, nil)



        guard case .configured(let authNState, _) = await authStateMachine.currentState,
              case .signingIn(let signInState) = authNState,
              case .resolvingChallenge(let challengeState, _, _) = signInState else {
            throw invalidStateError
        }

        switch challengeState {
        case .waitingForAnswer, .error:
            await sendConfirmSignInEvent()
        default:
            throw invalidStateError
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
                      case .error(_, _, let signInError) = challengeState {
                       let authError = signInError.authError
                       if case .service(_, _, let serviceError) = authError,
                          let cognitoError = serviceError as? AWSCognitoAuthError,
                          case .passwordResetRequired = cognitoError {
                           return AuthSignInResult(nextStep: .resetPassword(nil))

                       } else if case .service(_, _, let serviceError) = authError,
                                 let cognitoError = serviceError as? AWSCognitoAuthError,
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
