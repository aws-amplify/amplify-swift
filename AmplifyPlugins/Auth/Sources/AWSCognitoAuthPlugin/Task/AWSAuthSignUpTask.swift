//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class AWSAuthSignUpTask: AuthSignUpTask {

    private let request: AuthSignUpRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signUpAPI
    }

    init(_ request: AuthSignUpRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
    }

    func execute() async throws -> AuthSignUpResult {
        do {
            await didConfigure()
            try await validateCurrentState()
            let result = try await doSignUp()
            cancelToken()
            return result
        } catch {
            cancelToken()
            throw error
        }
    }

    private func didConfigure() async {
        await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Void, Never>) in
            stateMachineToken = authStateMachine.listen({ [weak self] state in
                guard let self = self, case .configured = state else { return }
                self.authStateMachine.cancel(listenerToken: self.stateMachineToken!)
                continuation.resume()
            }, onSubscribe: {})
        }
    }
    
    func validateCurrentState() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            authStateMachine.getCurrentState { [weak self] in
                guard case .configured(let authenticationState, _) = $0 else {
                    return
                }

                switch authenticationState {
                case .signedOut:
                    continuation.resume()
                case .signingUp:
                    let event = AuthenticationEvent(eventType: .cancelSignUp)
                    self?.authStateMachine.send(event)
                    continuation.resume()
                default:
                    let error = AuthError.invalidState("Auth state must be signed out to signup", "", nil)
                    continuation.resume(throwing: error)
                }
            }
        }

    }
    
    func doSignUp() async throws -> AuthSignUpResult {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<AuthSignUpResult, Error>) in
            stateMachineToken = authStateMachine.listen { [weak self] state in
                guard let self = self, case .configured(let authNState, _) = state else {
                    return
                }
                switch authNState {
                case .signedOut:
                    self.sendSignUpEvent(continuation)
                case .signingUp(let signUpState):
                    switch signUpState {
                    case .signingUpInitiated(_, response: let response):
                        continuation.resume(returning: response.authResponse)
                    case .error(let error):
                        continuation.resume(throwing: error.authError)
                    default:
                        break
                    }
                default:
                    break
                }
            } onSubscribe: {}
        }
    }
    
    private func sendSignUpEvent(_ continuation: CheckedContinuation<AuthSignUpResult, Error>) {
        guard !request.username.isEmpty else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.signUpUsernameError.field,
                AuthPluginErrorConstants.signUpUsernameError.errorDescription,
                AuthPluginErrorConstants.signUpUsernameError.recoverySuggestion, nil)
            continuation.resume(throwing: error)
            return
        }

        guard let password = request.password,
           SignUpPasswordValidator.validate(password: password) == nil else {
               let error = AuthError.validation(
                AuthPluginErrorConstants.signUpPasswordError.field,
                AuthPluginErrorConstants.signUpPasswordError.errorDescription,
                AuthPluginErrorConstants.signUpPasswordError.recoverySuggestion, nil)
                continuation.resume(throwing: error)
            return
        }

        // Convert the attributes to [String: String]
        let attributes = request.options.userAttributes?.reduce(
            into: [String: String]()) {
                $0[$1.key.rawValue] = $1.value
            } ?? [:]
        let signUpData = SignUpEventData(username: request.username,
                                         password: password,
                                         attributes: attributes)
        let event = SignUpEvent(eventType: .initiateSignUp(signUpData))
        authStateMachine.send(event)
    }
    
    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }
}
