//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension DeleteUserState {
    
    struct Resolver: StateMachineResolver {
        
        var defaultState: DeleteUserState = .notStarted(nil)
        
        func resolve(oldState: DeleteUserState,
                     byApplying event: StateMachineEvent) -> StateResolution<DeleteUserState> {
            
            switch oldState {
                
            case .notStarted(let signedInData):
                if let deleteUserEvent = event.isDeleteUserEvent,
                   case .deleteUser(let accessToken) = deleteUserEvent,
                   let unwrappedSignedInData = signedInData {
                    let action = DeleteUser(accessToken: accessToken)
                    return .init(newState: .deletingUser(unwrappedSignedInData), actions: [action])
                }
                return .from(oldState)
                
            case .deletingUser(let signInData):
                if case .signOutDeletedUser = event.isDeleteUserEvent {
                    let action = InitiateSignOut(
                        signedInData: signInData,
                        signOutEventData: SignOutEventData(globalSignOut: true)
                    )
                    let newState = DeleteUserState.signingOut(.notStarted)
                    return .init(newState: newState, actions: [action])
                }
                return .from(oldState)
                
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
                let action = InformUserDeletedAndSignedOut(result: .success((signedOutData)))
                let newState = DeleteUserState.userDeleted(signedOutData)
                var resolutionActions = resolution.actions
                resolutionActions.append(action)
                return .init(newState: newState, actions: resolutionActions)
            case .error(let error):
                let action = InformUserDeletedAndSignedOut(result: .failure(error.authError))
                var resolutionActions = resolution.actions
                resolutionActions.append(action)
                let newState = DeleteUserState.error(error.authError)
                return .init(newState: newState, actions: resolutionActions)
            default:
                let newState = DeleteUserState.signingOut(resolution.newState)
                return .init(newState: newState, actions: resolution.actions)
            }
        }
    }
    
}
