//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension SignInState {

    struct Resolver: StateMachineResolver {

        typealias StateType = SignInState
        let defaultState = SignInState.notStarted

        func resolve(
            oldState: SignInState,
            byApplying event: StateMachineEvent)
        -> StateResolution<SignInState> {
            
            switch oldState {
            case .signingInWithSRP(let srpSignInState, let signInEventData):

                if let signInEvent = event as? SignInEvent {
                    switch signInEvent.eventType {
                    case .receivedSMSChallenge(let challenge):
                        let subState = SignInChallengeState.waitingForAnswer(challenge)
                        return .init(newState: .resolvingSMSChallenge(subState))
                    default:
                        return .from(oldState)
                    }
                }
                let resolution = SRPSignInState.Resolver().resolve(oldState: srpSignInState,
                                                                   byApplying: event)
                let signingInWithSRP = SignInState.signingInWithSRP(resolution.newState,
                                                                    signInEventData)
                return .init(newState: signingInWithSRP, actions: resolution.actions)

            case .resolvingSMSChallenge(let challengeState):
                let resolution = SignInChallengeState.Resolver().resolve(oldState: challengeState,
                                                                         byApplying: event)
                return .init(newState: .resolvingSMSChallenge(challengeState),
                             actions: resolution.actions)
            default:
                return .from(oldState)
            }
        }

    }
}
