//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

class AWSAuthSignUpTask: AuthSignUpTask, DefaultLogger {

    private let request: AuthSignUpRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authEnvironment: AuthEnvironment

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signUpAPI
    }

    init(_ request: AuthSignUpRequest, 
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
            log.verbose("Sign up")
            let result = try await doSignUp()
            log.verbose("Sign up received result")
            return result
        } catch {
            throw error
        }
        
    }
    
    private func doSignUp() async throws -> AuthSignUpResult {
        log.verbose("Sending sign up event")
        await sendSignUpEvent()
        log.verbose("Waiting for sign up to complete")
        
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(_, _, let signUpState) = state else { continue }
            
            switch signUpState {
            case .awaitingUserConfirmation(_, let result):
                return result
            case .signedUp(_, let result):
                return result
            case .error(let signUpError):
                throw signUpError.authError
            default:
                continue
            }
        }
        throw AuthError.unknown("Sign up reached an error state")
    }
    
    private func sendSignUpEvent() async {
        let pluginOptions = request.options.pluginOptions as? AWSAuthSignUpOptions
        let metaData = pluginOptions?.metadata
        let validationData = pluginOptions?.validationData
        let attributes = request.options.userAttributes
        
        let signUpEventData = SignUpEventData(
            username: request.username,
            clientMetadata: metaData,
            validationData: validationData
        )
        let event = SignUpEvent(eventType: .initiateSignUp(
            signUpEventData, 
            request.password,
            attributes)
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
