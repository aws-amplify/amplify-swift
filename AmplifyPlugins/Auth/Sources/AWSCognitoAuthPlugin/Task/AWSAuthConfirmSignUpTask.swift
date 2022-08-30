//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthConfirmSignUpTask: AuthConfirmSignUpTask {

    private let request: AuthConfirmSignUpRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignUpAPI
    }
    
    init(_ request: AuthConfirmSignUpRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
    }

    func execute() async throws -> AuthSignUpResult {
        do {
            try await validateCurrentState()
            let result = try await doConfirmSignUp()
            cancelToken()
            return result
        } catch {
            cancelToken()
            throw error
        }
    }
    
    func validateCurrentState() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            self?.authStateMachine.getCurrentState { state in
                guard case .configured(let authenticationState, _) = state else {
                    return
                }

                switch authenticationState {
                case .signedOut, .signingUp:
                    continuation.resume()
                default:
                    let error = AuthError.invalidState("Auth state must be signed out to signup", "", nil)
                    continuation.resume(throwing: error)
                }
            }
        }

    }
    
    func doConfirmSignUp() async throws -> AuthSignUpResult {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<AuthSignUpResult, Error>) in
            stateMachineToken = authStateMachine.listen { state in
                guard case .configured(let authNState, _) = state else {
                    return
                }

                switch authNState {
                case .signingUp(let signUpState):
                    switch signUpState {
                    case .signedUp:
                        continuation.resume(returning: AuthSignUpResult(.done))
                    case .error(let error):
                        continuation.resume(throwing: error.authError)
                    default:
                        break
                    }
                default:
                    break
                }
            } onSubscribe: { [weak self] in
                guard let self = self else { return }
                self.sendConfirmSignUpEvent(continuation)
            }
        }
    }
    
    private func sendConfirmSignUpEvent(_ continuation: CheckedContinuation<AuthSignUpResult, Error>) {
        guard !request.code.isEmpty else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.confirmSignUpCodeError.field,
                AuthPluginErrorConstants.confirmSignUpCodeError.errorDescription,
                AuthPluginErrorConstants.confirmSignUpCodeError.recoverySuggestion, nil)
            continuation.resume(throwing: error)
            return
        }
        let confirmSignUpData = ConfirmSignUpEventData(
            username: request.username,
            confirmationCode: request.code)
        let event = SignUpEvent(eventType: .confirmSignUp(confirmSignUpData))
        authStateMachine.send(event)
    }
    
    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
