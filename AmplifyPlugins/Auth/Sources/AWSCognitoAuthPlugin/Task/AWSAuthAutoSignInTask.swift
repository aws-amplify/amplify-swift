//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

class AWSAuthAutoSignInTask: AuthAutoSignInTask, DefaultLogger {
    private let request: AuthAutoSignInRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authEnvironment: AuthEnvironment

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.autoSignInAPI
    }

    init(_ request: AuthAutoSignInRequest,
         authStateMachine: AuthStateMachine,
         authEnvironment: AuthEnvironment) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.authEnvironment = authEnvironment
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignInResult {
        await taskHelper.didStateMachineConfigured()
        
        // Check if we have a user pool configuration
        let authConfiguration = authEnvironment.configuration
        guard let _ = authConfiguration.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

        try await validateCurrentState()

        do {
            log.verbose("Auto signing in")
            let result = try await doAutoSignIn()
            log.verbose("Received result")
            return result
        } catch {
            await waitForSignInCancel()
            throw error
        }
    }

    private func validateCurrentState() async throws {

        let stateSequences = await authStateMachine.listen()
        log.verbose("Validating current state")
        for await state in stateSequences {
            guard case .configured(let authenticationState, _, let signUpState) = state else {
                continue
            }
            
            guard case .signedUp = signUpState else {
                let error = AuthError.invalidState(
                    "Not in a signed up state. Please call signUp() and confirmSignUp() before calling autoSignIn()",
                    AuthPluginErrorConstants.invalidStateError, nil)
                throw error
            }

            switch authenticationState {
            case .signedIn:
                let error = AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil)
                throw error
            case .signingIn:
                log.verbose("Cancelling existing signIn flow")
                await sendCancelSignInEvent()
            case .configured, .signedOut:
                return
            default: continue
            }
        }
    }

    private func doAutoSignIn() async throws -> AuthSignInResult {
        log.verbose("Sending autoSignIn event")
        try await sendAutoSignInEvent()
        
        log.verbose("Waiting for autoSignIn to complete")
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, let authZState, _) = state else { continue }
            
            switch authNState {
            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else if case .error(let error) = authZState {
                    log.verbose("Authorization reached an error state \(error)")
                    throw error.authError
                }
            case .error(let error):
                throw error.authError
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
    
    private func sendCancelSignInEvent() async {
        let event = AuthenticationEvent(eventType: .cancelSignIn)
        await authStateMachine.send(event)
    }
    
    private func waitForSignInCancel() async {
        await sendCancelSignInEvent()
        let stateSequences = await authStateMachine.listen()
        log.verbose("Wait for signIn to cancel")
        for await state in stateSequences {
            guard case .configured(let authenticationState, _, _) = state else {
                continue
            }
            switch authenticationState {
            case .signedOut:
                return
            default: continue
            }
        }
    }
    
    private func sendAutoSignInEvent() async throws {
        let currentState = await authStateMachine.currentState
        guard case .configured(_, _, let signUpState) = currentState  else {
            let message = "Auth state machine not in configured state: \(currentState)"
            let error = AuthError.invalidState(message, "", nil)
            throw error
        }
        
        guard case .signedUp(let data, _) = signUpState else {
            throw AuthError.invalidState("Auth state machine not in signed up state: \(currentState)", "", nil)
        }
        
        let signInEventData = SignInEventData(
            username: data.username,
            password: nil,
            clientMetadata: data.clientMetadata ?? [:],
            signInMethod: .apiBased(.userAuth),
            session: data.session)
        
        let event = AuthenticationEvent(eventType: .signInRequested(signInEventData, true))
        await authStateMachine.send(event)
    }
}
