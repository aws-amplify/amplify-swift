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
    private let taskHelper: AWSAuthTaskHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInAPI
    }
    
    init(_ request: AuthSignInRequest, authStateMachine: AuthStateMachine) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignInResult {
        await taskHelper.didStateMachineConfigured()
        try await validateCurrentState()
        return try await doSignIn()
    }

    private func validateCurrentState() async throws {

        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }

            switch authenticationState {
            case .signedIn:
                let error = AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil)
                throw error
            case .signedOut:
                break
            default: continue
            }
        }
    }

    private func doSignIn() async throws -> AuthSignInResult {
        let stateSequences = await authStateMachine.listen()
        await sendSignInEvent()
        for await state in stateSequences {
            guard case .configured(let authNState,
                                   let authZState) = state else { continue }

            switch authNState {

            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else if case .error(let error) = authZState {
                    let error = AuthError.unknown("Sign in reached an error state", error)
                    throw error
                }
            case .error(let error):
                let error = AuthError.unknown("Sign in reached an error state", error)
                throw error

            case .signingIn(let signInState):
                guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                    continue
                }
                return result
            default:
                continue
            }
        }
        throw AuthError.unknown("Sign in reached an error state")
    }

    private func sendSignInEvent() async {
        let signInData = SignInEventData(
            username: request.username,
            password: request.password,
            clientMetadata: clientMetadata(),
            signInMethod: .apiBased(authFlowType())
        )
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        await authStateMachine.send(event)
    }

    private func authFlowType() -> AuthFlowType {
        (request.options.pluginOptions as? AWSAuthSignInOptions)?.authFlowType ?? .unknown
    }

    private func clientMetadata() -> [String: String] {
        (request.options.pluginOptions as? AWSAuthSignInOptions)?.metadata ?? [:]
    }
}
