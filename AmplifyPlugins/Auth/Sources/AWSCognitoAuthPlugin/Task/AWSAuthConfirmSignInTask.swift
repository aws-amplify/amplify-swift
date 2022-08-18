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
    private var stateListenerToken: AuthStateMachineToken?
    
    init(_ request: AuthConfirmSignInRequest, stateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = stateMachine
        super.init(eventName: HubPayload.EventName.Auth.confirmSignInAPI)
    }
    
    override var value: AuthSignInResult {
        get async throws {
            return try await execute()
        }
    }

    private func execute() async throws -> AuthSignInResult {
        if let validationError = request.hasError() {
            dispatch(result: .failure(validationError))
            throw validationError
        }
        
        return try await withCheckedThrowingContinuation{ (continuation: CheckedContinuation<AuthSignInResult, Error>) in
            let invalidStateError = AuthError.invalidState("User is not attempting signIn operation",
                                                           AuthPluginErrorConstants.invalidStateError, nil)

            stateListenerToken = authStateMachine.listen { [weak self] state in
                guard let self = self, case .configured(let authNState, let authZState) = state else {
                    self?.dispatch(result: .failure(invalidStateError))
                    self?.cancelToken(self?.stateListenerToken)
                    continuation.resume(throwing: invalidStateError)
                    return
                }
                switch authNState {
                case .signedIn:
                    if case .sessionEstablished = authZState {
                        let result = AuthSignInResult(nextStep: .done)
                        self.dispatch(result: .success(result))
                        self.cancelToken(self.stateListenerToken)
                        continuation.resume(returning: result)
                    }
                case .error(let error):
                    let authError = AuthError.unknown("Sign in reached an error state", error)
                    self.dispatch(result: .failure(authError))
                    self.cancelToken(self.stateListenerToken)
                    continuation.resume(throwing: authError)
                case .signingIn(let signInState):
                    if case .resolvingChallenge(let challengeState, _) = signInState,
                       case .error(_, let signInError) = challengeState {
                        let authError = signInError.authError
                        if case .service(_, _, let serviceError) = authError,
                           let cognitoError = serviceError as? AWSCognitoAuthError,
                           case .passwordResetRequired = cognitoError {
                            let result = AuthSignInResult(nextStep: .resetPassword(nil))
                            self.dispatch(result: .success(result))
                            self.cancelToken(self.stateListenerToken)
                            continuation.resume(returning: result)
                        } else if case .service(_, _, let serviceError) = authError,
                                  let cognitoError = serviceError as? AWSCognitoAuthError,
                                  case .userNotConfirmed = cognitoError {
                            let result = AuthSignInResult(nextStep: .confirmSignUp(nil))
                            self.dispatch(result: .success(result))
                            self.cancelToken(self.stateListenerToken)
                            continuation.resume(returning: result)
                        } else {
                            self.dispatch(result: .failure(authError))
                            self.cancelToken(self.stateListenerToken)
                            continuation.resume(throwing: authError)
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
                            self.authStateMachine.send(event)
                        default:
                            return
                        }
                    }
                default:
                    self.dispatch(result: .failure(invalidStateError))
                    self.cancelToken(self.stateListenerToken)
                    continuation.resume(throwing: invalidStateError)
                }
            } onSubscribe: { }
        }
    }
    
    private func cancelToken(_ token: AuthStateMachineToken?) {
        if let token = token {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
