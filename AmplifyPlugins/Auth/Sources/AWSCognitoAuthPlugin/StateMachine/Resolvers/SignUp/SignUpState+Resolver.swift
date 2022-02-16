//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension SignUpState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SignUpState
        let defaultState = SignUpState.notStarted

        init() { }

        func resolve(
            oldState: StateType,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignUpState> {
            guard let signUpEvent = event as? SignUpEvent else {
                return .from(oldState)
            }

            let defaultState = {
                StateResolution(newState: oldState)
            }

            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: signUpEvent) ?? defaultState()
            case .initiatingSigningUp:
                return resolveInitiatingSigningUp(byApplying: signUpEvent) ?? defaultState()
            case .confirmingSignUp:
                return resolveConfirmingSignUp(byApplying: signUpEvent) ?? defaultState()
            case .signingUpInitiated:
                return resolveSigningUpInitiated(byApplying: signUpEvent) ?? defaultState()
            case .signedUp:
                return defaultState()
            case .error(_):
                return defaultState()
            }
        }

        // MARK: - Private Resolver Functions -

        private func resolveNotStarted(byApplying signInEvent: SignUpEvent) -> StateResolution<SignUpState>? {
            switch signInEvent.eventType {
            case .initiateSignUp(let signUpEventData):
                let action = InitiateSignUp(signUpEventData: signUpEventData)
                return StateResolution(newState: SignUpState.initiatingSigningUp(signUpEventData), actions: [action])
            case .confirmSignUp(let confirmSignUpEventData):
                let action = ConfirmSignUp(confirmSignUpEventData: confirmSignUpEventData)
                return StateResolution(newState: SignUpState.confirmingSignUp(confirmSignUpEventData), actions: [action])
            default:
                return nil
            }
        }

        private func resolveInitiatingSigningUp(byApplying signInEvent: SignUpEvent) -> StateResolution<SignUpState>? {
            switch signInEvent.eventType {
            case .initiateSignUpSuccess(username: let username, signUpResponse: let response):
                return StateResolution(newState: .signingUpInitiated(username: username,
                                                                     response: response))
            case .initiateSignUpFailure(let error):
                let action = CancelSignUp()
                return StateResolution(newState: .error(error), actions: [action])
            default:
                return nil
            }
        }

        private func resolveSigningUpInitiated(byApplying signInEvent: SignUpEvent) -> StateResolution<SignUpState>? {
            switch signInEvent.eventType {
            case .initiateSignUp(let signUpEventData):
                let action = InitiateSignUp(signUpEventData: signUpEventData)
                return StateResolution(newState: SignUpState.initiatingSigningUp(signUpEventData), actions: [action])
            case .confirmSignUp(let confirmSignUpEventData):
                let action = ConfirmSignUp(confirmSignUpEventData: confirmSignUpEventData)
                return StateResolution(newState: SignUpState.confirmingSignUp(confirmSignUpEventData), actions: [action])
            default:
                return nil
            }
        }

        private func resolveConfirmingSignUp(byApplying signInEvent: SignUpEvent) -> StateResolution<SignUpState>? {
            switch signInEvent.eventType {
            case .confirmSignUp(let confirmSignUpEventData):
                let action = ConfirmSignUp(confirmSignUpEventData: confirmSignUpEventData)
                return StateResolution(newState: SignUpState.confirmingSignUp(confirmSignUpEventData), actions: [action])
            case .confirmSignUpSuccess:
                let action = CancelSignUp()
                return StateResolution(newState: .signedUp, actions: [action])
            case .confirmSignUpFailure(let error):
                let action = CancelSignUp()
                return StateResolution(newState: .error(error), actions: [action])
            default:
                return nil
            }
        }

    }
}
