//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpTask: AuthConfirmSignUpTask, DefaultLogger {

    private let request: AuthConfirmSignUpRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authEnvironment: AuthEnvironment

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignUpAPI
    }

    init(_ request: AuthConfirmSignUpRequest,
         authStateMachine: AuthStateMachine,
         authEnvironment: AuthEnvironment) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.authEnvironment = authEnvironment
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws -> AuthSignUpResult {
        await taskHelper.didStateMachineConfigured()
        try request.hasError()
        try await validateCurrentState()
        
        do {
            log.verbose("Confirm sign up")
            let result = try await doConfirmSignUp()
            log.verbose("Confirm sign up received result")
            return result
        } catch {
            throw error
        }
    }
    
    private func doConfirmSignUp() async throws -> AuthSignUpResult {
        log.verbose("Sending confirmSignUp event")
        try await sendConfirmSignUpEvent()
        log.verbose("Waiting for confirm signup to complete")
        
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(_, _, let signUpState) = state else { continue }

            switch signUpState {
            case .signedUp(_, let result):
                return result
            case .error(let signUpError):
                throw signUpError.authError
            default:
                continue
            }
        }
        throw AuthError.unknown("Confirm sign up reached an error state")
    }
    
    private func sendConfirmSignUpEvent() async throws {
        let currentState = await authStateMachine.currentState
        guard case .configured(_, _, let signUpState) = currentState  else {
            let message = "Auth state machine not in configured state: \(currentState)"
            let error = AuthError.invalidState(message, "", nil)
            throw error
        }
        
        var session: String?
        if case .awaitingUserConfirmation(let data, _) = signUpState,
           request.username == data.username {
            // only include session if the cached username matches
            // the username in confirmSignUp() call
            session = data.session
        }
        
        let pluginOptions = request.options.pluginOptions as? AWSAuthConfirmSignUpOptions
        let metaData = pluginOptions?.metadata
        let forceAliasCreation = pluginOptions?.forceAliasCreation
        
        let signUpEventData = SignUpEventData(
            username: request.username,
            clientMetadata: metaData,
            session: session)
        let event = SignUpEvent(
            eventType: .confirmSignUp(
            signUpEventData,
            request.code, 
            forceAliasCreation)
        )
        await authStateMachine.send(event)
    }
    
    private func validateCurrentState() async throws {
        let stateSequences = await authStateMachine.listen()
        log.verbose("Validating current state")
        for await state in stateSequences {
            guard case .configured(_, _, let signUpState) = state else {
                continue
            }
            
            switch signUpState {
            case .notStarted, .awaitingUserConfirmation, .error, .signedUp:
                return
            default:
                continue
            }
        }
    }
}
