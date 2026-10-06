//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package extension DeleteUserState {

    struct Resolver: StateMachineResolver {

        package var defaultState: DeleteUserState = .notStarted

        package let signedInData: SignedInData

        package func resolve(
            oldState: DeleteUserState,
            byApplying event: StateMachineEvent
        ) -> StateResolution<DeleteUserState> {

            switch oldState {

            case .notStarted:
                guard let deleterUserEvent = event.isDeleteUserEvent else {
                    return .from(oldState)
                }
                switch deleterUserEvent {
                case .deleteUser(let accessToken, let skipHostedUISignOut):
                    let action = DeleteUser(accessToken: accessToken, skipHostedUISignOut: skipHostedUISignOut)
                    return .init(newState: .deletingUser, actions: [action])
                case .throwError(let error):
                    return .init(newState: .error(error))
                default:
                    return .from(oldState)
                }

            case .deletingUser:
                guard let deleterUserEvent = event.isDeleteUserEvent else {
                    return .from(oldState)
                }
                switch deleterUserEvent {
                case .signOutDeletedUser(let skipHostedUISignOut):
                    let action = InitiateSignOut(
                        signedInData: signedInData,
                        signOutEventData: SignOutEventData(globalSignOut: true, skipHostedUISignOut: skipHostedUISignOut)
                    )
                    let newState = DeleteUserState.signingOut(.notStarted)
                    return .init(newState: newState, actions: [action])
                case .throwError(let error):
                    return .init(newState: .error(error))
                default:
                    return .from(oldState)
                }

            case .signingOut(let signOutState):
                return resolveSigningOutState(byApplying: event, to: signOutState)

            case .userDeleted, .error:
                return .from(oldState)
            }

        }

        private func resolveSigningOutState(
            byApplying event: StateMachineEvent,
            to signOutState: SignOutState
        ) -> StateResolution<StateType> {
            let resolver = SignOutState.Resolver()
            let resolution = resolver.resolve(oldState: signOutState, byApplying: event)
            switch resolution.newState {
            case .signedOut(let signedOutData):
                let action = InformUserDeletedAndSignedOut(result: .success(signedOutData))
                let newState = DeleteUserState.userDeleted(signedOutData)
                var resolutionActions = resolution.actions
                resolutionActions.append(action)
                return .init(newState: newState, actions: resolutionActions)
            case .error(let error):
                let action = InformUserDeletedAndSignedOut(result: .failure(error.engineError))
                var resolutionActions = resolution.actions
                resolutionActions.append(action)
                let newState = DeleteUserState.error(error.engineError)
                return .init(newState: newState, actions: resolutionActions)
            default:
                let newState = DeleteUserState.signingOut(resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }
        }
    }

}
