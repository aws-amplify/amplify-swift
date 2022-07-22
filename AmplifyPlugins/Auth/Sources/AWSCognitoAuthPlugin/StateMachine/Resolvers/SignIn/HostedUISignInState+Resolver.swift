//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension HostedUISignInState {

    struct Resolver: StateMachineResolver {

        typealias StateType = HostedUISignInState
        let defaultState = HostedUISignInState.notStarted

        func resolve(
            oldState: HostedUISignInState,
            byApplying event: StateMachineEvent)
        -> StateResolution<HostedUISignInState> {

            switch oldState {

            case .notStarted:
                if case .showHostedUI(let signedInData) = event.isHostedUIEvent {
                    let action = ShowHostedUISignIn(signInData: signedInData)
                    return .init(newState: .showingUI(signedInData), actions: [action])
                }
                return .from(oldState)

            case .showingUI(_):
                if case .throwError(let error) = event.isHostedUIEvent {
                    let action = CancelSignIn()
                    return .init(newState: .error(error), actions: [action])
                }

                if case .fetchToken(let result) = event.isHostedUIEvent {
                    let action = FetchHostedUISignInToken(result: result)
                    return .init(newState: .fetchingToken, actions: [action])
                }
                return .from(oldState)

            case .fetchingToken:
                if case .throwError(let error) = event.isHostedUIEvent {
                    let action = CancelSignIn()
                    return .init(newState: .error(error), actions: [action])
                }
                if case .finalizeSignIn(let signedInData) = event.isSignInEvent {
                    return .init(newState: .done,
                                 actions: [SignInComplete(signedInData: signedInData)])
                }

                return .from(oldState)

            case .done:
                return .from(oldState)

            case .error:
                return .from(oldState)

            }

        }

    }
}
