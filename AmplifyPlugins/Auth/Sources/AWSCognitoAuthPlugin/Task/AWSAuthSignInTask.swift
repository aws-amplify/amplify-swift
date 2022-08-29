//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInTask: AuthSignInTask {

    private let request: AuthSignInRequest
    private let authStateMachine: AuthStateMachine
    private var stateMachineToken: AuthStateMachineToken?

    init(_ request: AuthSignInRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        super.init(eventName: HubPayload.EventName.Auth.signInAPI)
    }

    override func execute() async throws -> AuthSignInResult {
        await didConfigure()
        try await validateCurrentState()
        let result = try await doSignIn()
        return result
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

    private func validateCurrentState() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            stateMachineToken = authStateMachine.listen({ state in
                guard let self = self, case .configured(let authenticationState, _) = state else {
                    return
                }

                switch authenticationState {
                case .signedIn:
                    let error = AuthError.invalidState(
                        "There is already a user in signedIn state. SignOut the user first before calling signIn",
                        AuthPluginErrorConstants.invalidStateError, nil)
                    self.cancelToken()
                    continuation.resume(throwing: error)
                case .signedOut:
                    self.cancelToken()
                    continuation.resume(with: .success(Void()))
                case .signingUp:
                    self.sendCancelSignUpEvent()
                default: break
                }
            }, onSubscribe: {})
        }
    }

    private func doSignIn() async throws -> AuthSignInResult {
        return try await withCheckedThrowingContinuation{ [weak self] (continuation: CheckedContinuation<AuthSignInResult, Error>) in
            stateMachineToken = authStateMachine.listen { [weak self] in
                guard let self = self else {
                    return
                }
                guard case .configured(let authNState,
                                       let authZState) = $0 else { return }

                switch authNState {

                case .signedIn:
                    if case .sessionEstablished = authZState {
                        let result = AuthSignInResult(nextStep: .done)
                        self.cancelToken()
                        continuation.resume(returning: result)
                    } else if case .error(let error) = authZState {
                        let error = AuthError.unknown("Sign in reached an error state", error)
                        self.cancelToken()
                        continuation.resume(throwing: error)
                    }
                case .error(let error):
                    let error = AuthError.unknown("Sign in reached an error state", error)
                    self.cancelToken()
                    continuation.resume(throwing: error)

                case .signingIn(let signInState):
                    guard let result = UserPoolSignInHelper.checkNextStep(signInState) else {
                        return
                    }
                    self.cancelToken()
                    continuation.resume(with: result)
                default:
                    break
                }
            } onSubscribe: { self?.sendSignInEvent() }
        }
    }

    private func sendSignInEvent() {
        let signInData = SignInEventData(
            username: request.username,
            password: request.password,
            clientMetadata: clientMetadata(),
            signInMethod: .apiBased(authFlowType())
        )
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        authStateMachine.send(event)
    }

    private func sendCancelSignUpEvent() {
        let event = AuthenticationEvent(eventType: .cancelSignUp)
        authStateMachine.send(event)
    }

    private func cancelToken() {
        if let token = stateMachineToken {
            authStateMachine.cancel(listenerToken: token)
        }
    }

    private func authFlowType() -> AuthFlowType {
        (request.options.pluginOptions as? AWSAuthSignInOptions)?.authFlowType ?? .unknown
    }

    private func clientMetadata() -> [String: String] {
        (request.options.pluginOptions as? AWSAuthSignInOptions)?.metadata ?? [:]
    }
}
