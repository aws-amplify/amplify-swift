//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension CustomSignInState {

    struct Resolver: StateMachineResolver {
        typealias StateType = CustomSignInState
        let defaultState = CustomSignInState.notStarted

        func resolve(
            oldState: CustomSignInState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<CustomSignInState> {

            guard let customSignInEvent = event as? SignInEvent else {
                return .from(oldState)
            }

            if case .throwAuthError(let authError) = customSignInEvent.eventType {
                return errorStateWithCancelSignIn(authError)
            }

            switch oldState {

            case .notStarted:
                return resolveNotStarted(byApplying: customSignInEvent)
            case .initiating:
                return resolveInitiating(from: oldState, byApplying: customSignInEvent)
            default:
                return .from(oldState)

            }
        }

        private func resolveNotStarted(byApplying signInEvent: SignInEvent) -> StateResolution<CustomSignInState> {
            switch signInEvent.eventType {
            case .initiateCustomSignIn(let signInEventData):
                guard let username = signInEventData.username, !username.isEmpty else {
                    let error = SignInError.inputValidation(
                        field: AuthPluginErrorConstants.signInUsernameError.field
                    )
                    return errorStateWithCancelSignIn(error)
                }
                let action = InitiateCustomAuth(
                    username: username,
                    clientMetadata: signInEventData.clientMetadata,
                    deviceMetadata: DeviceMetadata.noData)
                return StateResolution(
                    newState: CustomSignInState.initiating(signInEventData),
                    actions: [action]
                )
            default:
                return .from(.notStarted)
            }
        }

        private func resolveInitiating(
            from oldState: CustomSignInState,
            byApplying signInEvent: SignInEvent) -> StateResolution<CustomSignInState> {
                switch signInEvent.eventType {
                case .finalizeSignIn(let signedInData):
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                default:
                    return .from(oldState)
                }
            }

        private func errorStateWithCancelSignIn(_ error: SignInError)
        -> StateResolution<CustomSignInState> {
            let action = CancelSignIn()
            return StateResolution(
                newState: CustomSignInState.error(error),
                actions: [action]
            )
        }
    }
}
