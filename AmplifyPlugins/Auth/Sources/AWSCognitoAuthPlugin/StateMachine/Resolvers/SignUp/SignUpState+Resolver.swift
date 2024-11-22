//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension SignUpState {
    struct Resolver: StateMachineResolver {
        typealias StateType = SignUpState
        let defaultState = SignUpState.notStarted

        init() { }

        func resolve(
            oldState: SignUpState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<SignUpState> {
            guard let signUpEvent = event as? SignUpEvent else {
                return .from(oldState)
            }
            switch oldState {
            case .notStarted:
                return resolveNotStarted(byApplying: signUpEvent, from: oldState)
            case .initiatingSignUp:
                return resolveInitiatingSignUp(byApplying: signUpEvent, from: oldState)
            case .awaitingUserConfirmation:
                return resolveAwaitingUserConfirmation(byApplying: signUpEvent, from: oldState)
            case .confirmingSignUp:
                return resolveConfirmingSignUp(byApplying: signUpEvent, from: oldState)
            case .signedUp:
                return resolveSignedUp(byApplying: signUpEvent, from: oldState)
            case .error:
                return resolveError(byApplying: signUpEvent, from: oldState)
            }
        }

        private func resolveNotStarted(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            case .throwAuthError(let error):
                return .init(newState: .error(error))
            default:
                return .from(oldState)
            }
        }
        
        private func resolveError(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            default:
                return .from(oldState)
            }
        }
        
        private func resolveInitiatingSignUp(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .initiateSignUpComplete(let data, let result):
                return .init(newState: .awaitingUserConfirmation(data, result))
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            case .signedUp(let data, let result):
                return .init(newState: .signedUp(data, result))
            case .throwAuthError(let error):
                return .init(newState: .error(error))
            }
        }
        
        private func resolveAwaitingUserConfirmation(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            case .throwAuthError(let error):
                return .init(newState: .error(error))
            default:
                return .from(oldState)
            }
        }
        
        private func resolveConfirmingSignUp(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            case .signedUp(let data, let result):
                return .init(newState: .signedUp(data, result))
            case .throwAuthError(let error):
                return .init(newState: .error(error))
            default:
                return .from(oldState)
            }
        }
        
        private func resolveSignedUp(
            byApplying signUpEvent: SignUpEvent,
            from oldState: SignUpState
        ) -> StateResolution<SignUpState> {
            switch signUpEvent.eventType {
            case .initiateSignUp(let data, let password, let userAttributes):
                let action = InitiateSignUp(data: data, password: password, attributes: userAttributes)
                return .init(newState: .initiatingSignUp(data), actions: [action])
            case .confirmSignUp(let data, let code, let forceAliasCreation):
                let action = ConfirmSignUp(data: data, confirmationCode: code, forceAliasCreation: forceAliasCreation)
                return .init(newState: .confirmingSignUp(data), actions: [action])
            case .throwAuthError(let error):
                return .init(newState: .error(error))
            default:
                return .from(oldState)
            }
        }
    }
}
