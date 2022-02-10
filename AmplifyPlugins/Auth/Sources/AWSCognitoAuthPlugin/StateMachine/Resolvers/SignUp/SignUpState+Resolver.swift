//// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension SignUpState {
    struct Resolver: StateMachineResolver {
        public typealias StateType = SignUpState
        public let defaultState = SignUpState.notStarted

        public init() { }

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
            default:
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
            case .initiateSignUpSuccess:
                return StateResolution(newState: .signingUpInitiated)
            case .initiateSignUpFailure(let error):
                return StateResolution(newState: .error(error))
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
                return StateResolution(newState: .signedUp)
            case .confirmSignUpFailure(let error):
                return StateResolution(newState: .error(error))
            default:
                return nil
            }
        }

    }
}
