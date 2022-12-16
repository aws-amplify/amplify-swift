//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension MigrateSignInState {

    struct Resolver: StateMachineResolver {
        typealias StateType = MigrateSignInState
        let defaultState = MigrateSignInState.notStarted

        func resolve(
            oldState: MigrateSignInState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<MigrateSignInState> {

            guard let signInEvent = event as? SignInEvent else {
                return .from(oldState)
            }

            if case .throwAuthError(let authError) = signInEvent.eventType {
                return errorStateWithCancelSignIn(authError)
            }

            switch oldState {

            case .notStarted:
                return resolveNotStarted(byApplying: signInEvent)
            case .signingIn:
                return resolveInitiating(from: oldState, byApplying: signInEvent)
            default:
                return .from(oldState)

            }
        }

        private func resolveNotStarted(byApplying signInEvent: SignInEvent)
        -> StateResolution<MigrateSignInState> {
            switch signInEvent.eventType {
            case .initiateMigrateAuth(let signInEventData, let deviceMetadata):
                guard let username = signInEventData.username, !username.isEmpty else {
                    let error = SignInError.inputValidation(
                        field: AuthPluginErrorConstants.signInUsernameError.field
                    )
                    return errorStateWithCancelSignIn(error)
                }
                guard let password = signInEventData.password,
                        !password.isEmpty else {
                    let error = SignInError.inputValidation(
                        field: AuthPluginErrorConstants.signInPasswordError.field
                    )
                    return errorStateWithCancelSignIn(error)
                }
                let action = InitiateMigrateAuth(
                    username: username,
                    password: password,
                    clientMetadata: signInEventData.clientMetadata,
                    deviceMetadata: deviceMetadata)
                return StateResolution(
                    newState: MigrateSignInState.signingIn(signInEventData),
                    actions: [action]
                )
            default:
                return .from(.notStarted)
            }
        }

        private func resolveInitiating(
            from oldState: MigrateSignInState,
            byApplying signInEvent: SignInEvent) -> StateResolution<MigrateSignInState> {
                switch signInEvent.eventType {
                case .finalizeSignIn(let signedInData):
                    return .init(newState: .signedIn(signedInData),
                                 actions: [SignInComplete(signedInData: signedInData)])
                default:
                    return .from(oldState)
                }
            }

        private func errorStateWithCancelSignIn(_ error: SignInError)
        -> StateResolution<MigrateSignInState> {
            return StateResolution(
                newState: MigrateSignInState.error(error)
            )
        }
    }
}
