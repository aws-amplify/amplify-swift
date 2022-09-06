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
        
        await taskHelper.didStateMachineConfigured()

        let invalidStateError = AuthError.invalidState(
            "User is not attempting signIn operation",
            AuthPluginErrorConstants.invalidStateError, nil)
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
                   if case .resolvingChallenge(let challengeState, _) = signInState,
                      case .error(_, let signInError) = challengeState {
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
                   } else if case .resolvingChallenge(let challengeState, _) = signInState {
                       switch challengeState {
                       case .waitingForAnswer(_):
                           // Convert the attributes to [String: String]
                           let attributePrefix = AuthPluginConstants.cognitoIdentityUserUserAttributePrefix
                           let attributes = self.request.options.userAttributes?.reduce(
                               into: [String: String]()) {
                                   $0[attributePrefix + $1.key.rawValue] = $1.value
                               } ?? [:]
                           let confirmSignInData = ConfirmSignInEventData(
                               answer: self.request.challengeResponse,
                               attributes: attributes)
                           let event = SignInChallengeEvent(
                               eventType: .verifyChallengeAnswer(confirmSignInData))
                           await authStateMachine.send(event)
                       default:
                           continue
                       }
                   }
               default:
                   throw invalidStateError
               }
        }
        throw invalidStateError
    }
    
}
